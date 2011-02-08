use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'insert using txn_scope' => sub {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    {
        my $guard = $db->txn_scope();
        my $row = $db->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'Teng::Row';
        is $row->name, 'perl';
        $guard->rollback;
    }

    if (! ok ! $warning, "no warnings received") {
        diag "got $warning";
    }
};

subtest 'insert using txn_scope (and let the guard fire)' => sub {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    {
        my $guard = $db->txn_scope();
        my $row = $db->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'Teng::Row';
        is $row->name, 'perl';
    }

    like $warning, qr{Guard created at \.?\/?t/002_common/024_txn_scope\.t line 32};
};

done_testing;

