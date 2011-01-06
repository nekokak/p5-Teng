use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'update/delete error: no table info' => sub {
    my $row = Mock::Basic->search_by_sql(q{SELECT name FROM mock_basic})->first;

    isa_ok $row, 'DBIx::Skinny::Row';

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
    my $row = Mock::Basic->single('mock_basic',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';

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
    Mock::Basic->schema->schema_info->{mock_basic}->{pk} = undef;

    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skinny::Row';

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

    Mock::Basic->schema->schema_info->{mock_basic}->{pk} = 'id';
};

subtest 'update/delete error: select column have no pk.' => sub {
    my $row = Mock::Basic->resultset(
        {
            select => [qw/name/],
            from   => [qw/mock_basic/],
        }
    )->retrieve->first;

    isa_ok $row, 'DBIx::Skinny::Row';

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


