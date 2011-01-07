use t::Utils;
use Test::More;

{
    package Mock::BasicOnConnectDo;
    our $CONNECTION_COUNTER;
    use DBIx::Skin;

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
    use DBIx::Skin::Schema;

    install_table mock_basic => schema {
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
            dsn => 'dbi:SQLite:./t/main.db',
            username => '',
            password => '',
            on_connect_do => sub { $Mock::BasicOnConnectDo::CONNECTION_COUNTER++ }
        }
    );

    $db->connect; # for do connection.
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 1, "counter should called");
    $db->reconnect;
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 2, "called after reconnect");
    $db->reconnect;
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 3, "called after reconnect");
};

subtest 'instance level on_connect_do / coderef' => sub {
    my $counter = 0;
    my $db = Mock::BasicOnConnectDo->new(
        {
            dsn => 'dbi:SQLite:./t/main.db',
            username => '',
            password => '',
            on_connect_do => sub { $counter++ },
        }
    );

    $db->connect; # for do connection.
    is($counter, 1, "counter should called");
    $db->reconnect;
    is($counter, 2, "called after reconnect");
    $db->reconnect;
    is($counter, 3, "called after reconnect");
};

subtest 'instance level on_connect_do / scalar' => sub {
    my $query;
    local *Mock::BasicOnConnectDo::do = sub {
        my ($self, $sql, ) = @_;
        $query = $sql;
    };
    my $db = Mock::BasicOnConnectDo->new(
        +{
            dsn => 'dbi:SQLite:',
            username => '',
            password => '',
            on_connect_do => 'select * from sqlite_master',
        }
    );

    $db->connect;
    is $query, 'select * from sqlite_master';
    $query='';
    $db->reconnect;
    is $query, 'select * from sqlite_master';
};

subtest 'instance level on_connect_do / array' => sub {
    my @query;
    local *Mock::BasicOnConnectDo::do = sub {
        my ($self, $sql, ) = @_;
        push @query, $sql;
    };
    my $db = Mock::BasicOnConnectDo->new({
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
        on_connect_do => ['select * from sqlite_master', 'select * from sqlite_master'],
    });

    $db->connect; 
    is_deeply \@query, ['select * from sqlite_master', 'select * from sqlite_master'];
    @query = ();
    $db->reconnect;
    is_deeply \@query, ['select * from sqlite_master', 'select * from sqlite_master'];
};

unlink './t/main.db';

done_testing();

