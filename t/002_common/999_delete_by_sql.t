use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'delete mock_basic data' => sub {
    local $SIG{__WARN__} = sub {};
    my $ret = $db->delete_by_sql(q{DELETE FROM mock_basic WHERE name = ?}, ['perl']);
    ok $ret;
};

done_testing;

