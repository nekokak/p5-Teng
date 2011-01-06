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

subtest 'update mock_basic data' => sub {
    local $SIG{__WARN__} = sub {};
    my $ret = $db->update_by_sql(q{UPDATE mock_basic SET name = ?}, ['ruby']);
    ok $ret;
    is +$db->single('mock_basic',{})->name, 'ruby';
};

done_testing;

