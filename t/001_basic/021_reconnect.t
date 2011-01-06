use t::Utils;
use Mock::Basic;
use Test::More;

Mock::Basic->reconnect(
    {
        dsn => 'dbi:SQLite:./db1.db',
        username => '',
        password => '',
    }
);
Mock::Basic->setup_test_db;

subtest 'db1.db ok' => sub {
    isa_ok +Mock::Basic->dbh, 'DBI::db';
    Mock::Basic->insert('mock_basic',
        {
            id   => 1,
            name => 'perl',
        }
    );
    
    my $itr = Mock::Basic->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

Mock::Basic->reconnect(
    {
        dsn => 'dbi:SQLite:./db2.db',
        username => '',
        password => '',
    }
);
Mock::Basic->setup_test_db;

subtest 'db2.db ok' => sub {
    isa_ok +Mock::Basic->dbh, 'DBI::db';
    Mock::Basic->insert('mock_basic',
        {
            id   => 1,
            name => 'ruby',
        }
    );

    my $itr = Mock::Basic->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id , 1;
    is $row->name, 'ruby';
};

Mock::Basic->reconnect(
    {
        dsn => 'dbi:SQLite:./db1.db',
        username => '',
        password => '',
    }
);

subtest 'db1.db ok' => sub {
    my $itr = Mock::Basic->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

Mock::Basic->reconnect();

subtest 'db1.db ok' => sub {
    my $itr = Mock::Basic->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
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

unlink qw{./db1.db db2.db};
done_testing;

