use t::Utils;
use Mock::Basic;
use Mock::Trigger;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;

=pod
my $db_trigger = Mock::Trigger->new({dbh => $dbh});
$db_trigger->setup_test_db;
=cut

subtest 'bulk_insert method' => sub {
    $db_basic->bulk_insert('mock_basic',[
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
    is +$db_basic->count('mock_basic', 'id'), 3;

=pod
    subtest 'pre_insert trigger should not work in bulk_insert' => sub {
        $db_trigger->bulk_insert('mock_trigger_pre' => [
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

        is +$db_trigger->count('mock_trigger_pre', 'id'), 3;
        my $item = $db_trigger->single(mock_trigger_pre => +{ id => 1});
        ok($item->name ne "pre_insert_s", "pre_insert should not work");
        is($item->name, "perl", "pre_insert should not work");
    };

    subtest 'post_insert trigger should not work in bulk_insert' => sub {
        $db_trigger->bulk_insert('mock_trigger_pre' => [
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

        is +$db_trigger->count('mock_trigger_post', 'id'), 0, "post_insert trigger should not work";
    };
=cut
};

done_testing;

