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

subtest 'search_by_sql' => sub {
    my $itr = Mock::Basic->search_by_sql(q{SELECT * FROM mock_basic WHERE id = ?}, [1]);
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

done_testing;

