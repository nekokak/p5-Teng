use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'delete mock_basic data' => sub {
    local $SIG{__WARN__} = sub {};
    my $ret = Mock::Basic->delete_by_sql(q{DELETE FROM mock_basic WHERE name = ?}, ['perl']);
    ok $ret;
};

done_testing;

