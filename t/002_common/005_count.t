use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'count' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    is +Mock::Basic->count('mock_basic' => 'id'), 1;

    Mock::Basic->insert('mock_basic',{
        id   => 2,
        name => 'ruby',
    });

    is +Mock::Basic->count('mock_basic' => 'id'), 2;
    is +Mock::Basic->count('mock_basic' => 'id',{name => 'perl'}), 1;
};

subtest 'iterator count' => sub {
    is +Mock::Basic->search('mock_basic',{  })->count, 2;
};

done_testing;
