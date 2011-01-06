use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'refetch' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'perl';

    my $refetch_row = $row->refetch;
    isa_ok $refetch_row, 'DBIx::Skinny::Row';
    is $refetch_row->name, 'perl';
};

done_testing;
