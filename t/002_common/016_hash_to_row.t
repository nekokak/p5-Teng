use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

{
    my $hash = +{
        id   => 1,
        name => 'perl',
    };

    my $row = Mock::Basic->hash_to_row('mock_basic', $hash);
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 1;
    is $row->name, 'perl';

    $row->insert;
}

{
    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 1;
    is $row->name, 'perl';
}

done_testing;
