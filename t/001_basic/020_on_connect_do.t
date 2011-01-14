use t::Utils;
use Test::More;

{
    package Mock::BasicOnConnectDo;
    our $CONNECTION_COUNTER;
    use parent qw/Teng/;

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_basic_on_connect_do (
                id   integer,
                name text,
                primary key ( id )
            )
        });
    }

    package Mock::BasicOnConnectDo::Schema;
    use utf8;
    use Teng::Schema::Declare;

    table {
        name 'mock_basic';
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

subtest 'global level on_connect_do / coderef' => sub {
    local $Mock::BasicOnConnectDo::CONNECTION_COUNTER = 0;

    my $db = Mock::BasicOnConnectDo->new(
        {
            connect_info => [
                'dbi:SQLite:./t/main.db',
                '',
                '',
            ],
            on_connect_do => sub { $Mock::BasicOnConnectDo::CONNECTION_COUNTER++ }
        }
    );

    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 1, "counter should called");
    $db->connect; # for do connection.
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 2, "called after reconnect");
};

subtest 'instance level on_connect_do / coderef' => sub {
    my $counter = 0;
    my $db = Mock::BasicOnConnectDo->new(
        {
            connect_info => [
                'dbi:SQLite:./t/main.db',
                '',
                '',
            ],
            on_connect_do => sub { $counter++ },
        }
    );

    is($counter, 1, "counter should called");
    $db->connect; # for do connection.
    is($counter, 2, "called after reconnect");
};

subtest 'instance level on_connect_do / scalar' => sub {
    my $query;
    local *Mock::BasicOnConnectDo::do = sub {
        my ($self, $sql, ) = @_;
        $query = $sql;
    };
    my $db = Mock::BasicOnConnectDo->new(
        +{
            connect_info => [
                'dbi:SQLite:./t/main.db',
                '',
                '',
            ],
            on_connect_do => 'select * from sqlite_master',
        }
    );

    is $query, 'select * from sqlite_master';
    $query='';
    $db->connect;
    is $query, 'select * from sqlite_master';
};

subtest 'instance level on_connect_do / array' => sub {
    my @query;
    local *Mock::BasicOnConnectDo::do = sub {
        my ($self, $sql, ) = @_;
        push @query, $sql;
    };
    my $db = Mock::BasicOnConnectDo->new(
        {
            connect_info => [
                'dbi:SQLite:./t/main.db',
                '',
                '',
            ],
            on_connect_do => ['select * from sqlite_master', 'select * from sqlite_master'],
        }
    );

    is_deeply \@query, ['select * from sqlite_master', 'select * from sqlite_master'];
    @query = ();
    $db->connect; 
    is_deeply \@query, ['select * from sqlite_master', 'select * from sqlite_master'];
};

unlink './t/main.db';

done_testing();

