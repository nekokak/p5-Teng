use t::Utils;
use Mock::Basic;
use Test::More;
use MyGuard;

my $db_file = __FILE__;
$db_file =~ s/\.t$/.db/;
unlink $db_file if -f $db_file;
my $db = Mock::Basic->new(
    {
        connect_info => [
           "dbi:SQLite:$db_file"
        ],
    }
);
$db->setup_test_db;
my $guard = MyGuard->new(sub { unlink $db_file });

subtest "$db_file ok" => sub {
    isa_ok +$db->dbh, 'DBI::db';
    $db->insert('mock_basic',
        {
            id   => 1,
            name => 'perl',
        }
    );
    
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

$db->reconnect(
    'dbi:SQLite:./db2.db',
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
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id , 1;
    is $row->name, 'ruby';
};

$db->reconnect(
    "dbi:SQLite:$db_file",
    '',
    '',
);

subtest "$db_file ok" => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

$db->reconnect();

subtest "$db_file ok" => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
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

subtest "recursion in auto reconnect as calling db->dbh" => sub {
    no strict 'refs';
    no warnings 'redefine';
    my $ping = ref($db->{dbh}) . '::ping';
    local *$ping = sub { 0 };
    undef $db->{txn_manager};

    is $db->{dbh}->FETCH('Active'), 1, 'test premise';
    is $db->{dbh}->ping, 0, 'test premise';
    ok $db->dbh, 'deep recursion';
};

done_testing;

