use t::Utils;
use Mock::Basic;
use Test::More;

TODO : {
todo_skip 'not yet...', 0;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'update/delete error: no table info' => sub {
    my $row = $db->search_by_sql(q{SELECT name FROM mock_basic})->next;

    isa_ok $row, 'DBIx::Skin::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@;
    like $@, qr/no table info/;

    eval {
        $row->delete;
    };
    ok $@;
    like $@, qr/no table info/;
};

subtest 'update/delete error: table name typo' => sub {
    my $row = $db->single('mock_basic',{id => 1});

    isa_ok $row, 'DBIx::Skin::Row';

    eval {
        $row->update({name => 'python'}, 'mock_basick');
    };
    ok $@;
    like $@, qr/unknown table: mock_basick/;

    eval {
        $row->delete('mock_basick');
    };
    ok $@;
    like $@, qr/unknown table: mock_basick/;
};

subtest 'update/delete error: table have no pk' => sub {
    $db->schema->schema_info->{mock_basic}->{pk} = undef;

    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skin::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@;
    like $@, qr/mock_basic have no pk./;

    eval {
        $row->delete;
    };
    ok $@;
    like $@, qr/mock_basic have no pk./;

    $db->schema->schema_info->{mock_basic}->{pk} = 'id';
};

subtest 'update/delete error: select column have no pk.' => sub {
    my $row = $db->resultset(
        {
            select => [qw/name/],
            from   => [qw/mock_basic/],
        }
    )->retrieve->next;

    isa_ok $row, 'DBIx::Skin::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@;
    like $@, qr/can't get primary column in your query./;

    eval {
        $row->delete;
    };
    ok $@;
    like $@, qr/can't get primary column in your query./;
};
done_testing;
};



