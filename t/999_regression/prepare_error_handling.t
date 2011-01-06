use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'prepare failed case' => sub {
    eval {
        $db->search_by_sql(q{xxxxx});
    };
    like $@, qr|DBD::SQLite::db prepare failed: near "xxxxx": syntax error|;
};

done_testing;
