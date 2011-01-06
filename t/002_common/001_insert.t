use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'insert mock_basic data/ insert method' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'perl';
};

subtest 'insert mock_basic data/ create method' => sub {
    my $row = Mock::Basic->create('mock_basic',{
        id   => 2,
        name => 'ruby',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'ruby';
};

done_testing;
