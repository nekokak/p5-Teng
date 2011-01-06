use t::Utils;
use Mock::Basic;
use Mock::Trigger;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

Mock::Trigger->set_dbh($dbh);
Mock::Trigger->setup_test_db;

subtest 'bulk_insert method' => sub {
    Mock::Basic->bulk_insert('mock_basic',[
        {
            id   => 1,
            name => 'perl',
        },
        {
            id   => 2,
            name => 'ruby',
        },
        {
            id   => 3,
            name => 'python',
        },
    ]);
    is +Mock::Basic->count('mock_basic', 'id'), 3;

    subtest 'pre_insert trigger should not work in bulk_insert' => sub {
        Mock::Trigger->bulk_insert('mock_trigger_pre' => [
            {
                id   => 1,
                name => 'perl',
            },
            {
                id   => 2,
                name => 'ruby',
            },
            {
                id   => 3,
                name => 'python',
            },
        ]);

        is +Mock::Trigger->count('mock_trigger_pre', 'id'), 3;
        my $item = Mock::Trigger->single(mock_trigger_pre => +{ id => 1});
        ok($item->name ne "pre_insert_s", "pre_insert should not work");
        is($item->name, "perl", "pre_insert should not work");
    };

    subtest 'post_insert trigger should not work in bulk_insert' => sub {
        Mock::Trigger->bulk_insert('mock_trigger_pre' => [
            {
                id   => 1,
                name => 'perl',
            },
            {
                id   => 2,
                name => 'ruby',
            },
            {
                id   => 3,
                name => 'python',
            },
        ]);

        is +Mock::Trigger->count('mock_trigger_post', 'id'), 0, "post_insert trigger should not work";
    };
};

done_testing;

