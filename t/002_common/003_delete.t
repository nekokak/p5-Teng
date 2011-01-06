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
    is +$db->count('mock_basic', 'id'), 1;

    $db->delete('mock_basic',{id => 1});

    is +$db->count('mock_basic', 'id'), 0;
};

subtest 'delete row count' => sub {
    $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    $db->insert('mock_basic',{
        id   => 2,
        name => 'perl',
    });

    my $deleted_count = $db->delete('mock_basic',{name => 'perl'});
    is $deleted_count, 2;
    is +$db->count('mock_basic', 'id'), 0;
};

subtest 'row object delete' => sub {
    $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    is +$db->count('mock_basic', 'id'), 1;

    my $row = $db->single('mock_basic',{id => 1})->delete;

    is +$db->count('mock_basic', 'id'), 0;
};

done_testing;
