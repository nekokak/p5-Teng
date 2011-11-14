use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;


subtest 'reconnect success' => sub {
    my $dbh = $db->dbh;
    eval { $db->reconnect; };
    ok(!$@);
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
