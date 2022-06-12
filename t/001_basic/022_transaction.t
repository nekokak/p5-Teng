use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'do basic transaction' => sub {
    $db->txn_begin;
    my $row = $db->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 1;
    is $row->name, 'perl';
    $db->txn_commit;

    is +$db->single('mock_basic',{id => 1})->name, 'perl';
};

subtest 'do rollback' => sub {
    $db->txn_begin;
    my $row = $db->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    $db->txn_rollback;

    ok not +$db->single('mock_basic',{id => 2});
};

subtest 'do commit' => sub {
    $db->txn_begin;
    my $row = $db->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    $db->txn_commit;

    ok +$db->single('mock_basic',{id => 2});
};

subtest 'error occurred in transaction' => sub {

    eval {
        local $SIG{__WARN__} = sub {};
        my $txn = $db->txn_scope;
        $db->{dbh} = undef;
        $db->connect;
    };
    my $e = $@;
    like $e, qr/Detected transaction during a connect operation \(last known transaction at/;
};

$db  = undef;
$dbh = undef;

subtest 'call_txn_scope_after_fork' => sub {
    my $dbh = t::Utils->setup_dbh('./fork_test.db');
    my $db  = Mock::Basic->new({dbh => $dbh});
    $db->setup_test_db;

    if (fork) {
        wait;
        my $row = $db->single('mock_basic',{name => 'python'});
        is $row->id, 3;
        is $dbh, $db->dbh;

        done_testing;
    } else {
        my $child_dbh = t::Utils->setup_dbh('./fork_test.db');
        my $child_db = Mock::Basic->new({dbh => $child_dbh});
        my $txn = $child_db->txn_scope;

            isnt $dbh,       $child_db->dbh;
            is   $child_dbh, $child_db->dbh;
            is   $child_dbh, $txn->[1]->{dbh};

            my $row = $child_db->insert('mock_basic',{
                id   => 3,
                name => 'python',
            });
            isa_ok $row, 'Teng::Row';
            is $row->name, 'python';

        $txn->commit;
        exit;
    }
    unlink './fork_test.db';
};

done_testing;

