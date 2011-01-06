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

subtest 'update mock_basic data' => sub {
    local $SIG{__WARN__} = sub {};
    my $ret = Mock::Basic->update_by_sql(q{UPDATE mock_basic SET name = ?}, ['ruby']);
    ok $ret;
    is +Mock::Basic->single('mock_basic',{})->name, 'ruby';
};

done_testing;

