use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

Mock::Basic->insert('mock_basic',
    {
        id   => 1,
        name => 'perl',
    }
);

subtest 'find_or_new' => sub {
    my $row = Mock::Basic->find_or_new('mock_basic',
        {
            id   => 1,
            name => 'perl',
        }
    );
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 1;
    is $row->name, 'perl';

    my $real_row = $row->insert;

    isa_ok $real_row, 'DBIx::Skinny::Row';
    is $real_row->id, 1;
    is $real_row->name, 'perl';

    is +Mock::Basic->count('mock_basic', 'id'), 1;
};

subtest 'find_or_new/ no data' => sub {
    my $row = Mock::Basic->find_or_new('mock_basic',
        {
            id   => 2,
            name => 'ruby',
        }
    );
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 2;
    is $row->name, 'ruby';

    my $real_row = $row->insert;

    isa_ok $real_row, 'DBIx::Skinny::Row';
    is $real_row->id, 2;
    is $real_row->name, 'ruby';

    is +Mock::Basic->count('mock_basic', 'id'), 2;
};

done_testing;

