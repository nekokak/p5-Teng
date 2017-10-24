use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

Mock::Basic->load_plugin('FindOrCreateBy');
can_ok 'Mock::Basic' => 'find_or_create_by';

subtest 'find_or_create_by' => sub {
    my $mock_basic = $db->find_or_create_by('mock_basic',{
        id   => 1,
        name => 'perl',
    }, sub {
        my $row = shift;
        $row->{delete_fg} = 1;
        return $row;
    });
    is $mock_basic->name, 'perl';
    is $mock_basic->delete_fg, 1, 'function should call';

    $mock_basic = $db->find_or_create_by('mock_basic',{
        id   => 1,
        name => 'perl',
    }, sub {
        my $row = shift;
        $row->{delete_fg} = 0;
        return $row;
    });
    is $mock_basic->name, 'perl';
    is $mock_basic->delete_fg, 1, 'function should not call';

    is +$db->count('mock_basic', 'id',{name => 'perl'}), 1;
};

subtest 'find_or_create_by' => sub {
    $db->delete('mock_basic');
    local $SIG{__WARN__} = sub{};
    eval {
        $db->find_or_create_by('mock_basic',{
            id   => 3,
            name => \' = "ruby"',
        }, sub {
            my $row = shift;
            $row->{delete_fg} = 0;
            return $row;
        });
    };
    ok $@;
};

done_testing;

