use t::Utils;
use Mock::Basic;
use Test::More;

my $db = Mock::Basic->new(
    {
        connect_info => [
            'dbi:SQLite::memory:',
            '',''
        ],
    }
);
$db->setup_test_db;


subtest 'reconnect success' => sub {
    my $dbh = $db->dbh;
    eval { $db->reconnect; };
    ok(!$@);
    ok($db->dbh);
    isnt($dbh, $db->dbh);

    # twice reconnect
    $dbh = $db->dbh;
    eval { $db->reconnect; };
    ok(!$@);
    ok($db->dbh);
    isnt($dbh, $db->dbh);
};

subtest 'in_transaction reconnect' => sub {
    my $dbh = $db->dbh;
    $db->txn_begin;
    eval { $db->reconnect; };
    ok($@);
    is($dbh, $db->dbh);
    $db->txn_commit;
};


done_testing;
