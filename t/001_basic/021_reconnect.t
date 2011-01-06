use t::Utils;
use Mock::Basic;
use Test::More;

my $db = Mock::Basic->new(
    {
        dsn => 'dbi:SQLite:./db1.db',
        username => '',
        password => '',
    }
);
$db->setup_test_db;
my $guard = MyGuard->new(sub { unlink 'db1.db' });

subtest 'db1.db ok' => sub {
    isa_ok +$db->dbh, 'DBI::db';
    $db->insert('mock_basic',
        {
            id   => 1,
            name => 'perl',
        }
    );
    
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skin::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

$db->reconnect(
    {
        dsn => 'dbi:SQLite:./db2.db',
        username => '',
        password => '',
    }
);
my $guard2 = MyGuard->new(sub { unlink 'db2.db' });
$db->setup_test_db;

subtest 'db2.db ok' => sub {
    isa_ok +$db->dbh, 'DBI::db';
    $db->insert('mock_basic',
        {
            id   => 1,
            name => 'ruby',
        }
    );

    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skin::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->id , 1;
    is $row->name, 'ruby';
};

$db->reconnect(
    {
        dsn => 'dbi:SQLite:./db1.db',
        username => '',
        password => '',
    }
);

subtest 'db1.db ok' => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skin::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

$db->reconnect();

subtest 'db1.db ok' => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skin::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

subtest '(re)connect fail' => sub {
    eval {
        Mock::Basic->reconnect(
            {
                dsn => 'dbi:mysql:must_not_exist_db',
                username => 'must_not_exist_user',
                password => 'arienai_password',
            }
        );
    };
    ok $@;
};

done_testing;

