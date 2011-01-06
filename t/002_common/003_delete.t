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
    is +Mock::Basic->count('mock_basic', 'id'), 1;

    Mock::Basic->delete('mock_basic',{id => 1});

    is +Mock::Basic->count('mock_basic', 'id'), 0;
};

subtest 'delete row count' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    Mock::Basic->insert('mock_basic',{
        id   => 2,
        name => 'perl',
    });

    my $deleted_count = Mock::Basic->delete('mock_basic',{name => 'perl'});
    is $deleted_count, 2;
    is +Mock::Basic->count('mock_basic', 'id'), 0;
};

subtest 'row object delete' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    is +Mock::Basic->count('mock_basic', 'id'), 1;

    my $row = Mock::Basic->single('mock_basic',{id => 1})->delete;

    is +Mock::Basic->count('mock_basic', 'id'), 0;
};

done_testing;
