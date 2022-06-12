use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'update/delete error: no table info' => sub {
    my $row = $db->search_by_sql(q{SELECT name FROM mock_basic})->next;

    isa_ok $row, 'Teng::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@, "Update fails w/o primary key";
    like $@, qr/can't get primary columns in your query/;

    eval {
        $row->delete;
    };
    ok $@, "Delete fails w/o primary key";
    like $@, qr/can't get primary columns in your query/;
};

subtest 'update/delete error: table have no pk' => sub {
    my $table = $db->schema->get_table('mock_basic');
    local $table->{primary_keys};

    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'Teng::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@;
    like $@, qr/mock_basic has no primary key/;

    eval {
        $row->delete;
    };
    ok $@;
    like $@, qr/mock_basic has no primary key/;
};

subtest 'update/delete error: table have no pk' => sub {
    my $table = $db->schema->get_table('mock_basic');
    local $table->{primary_keys} = [];

    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'Teng::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@;
    like $@, qr/mock_basic has no primary key/;

    eval {
        $row->delete;
    };
    ok $@;
    like $@, qr/mock_basic has no primary key/;
};

subtest 'update/delete error: select column has no primary key' => sub {
    my $row = $db->search_by_sql('select name from mock_basic')->next;
    isa_ok $row, 'Teng::Row';

    eval {
        $row->update({name => 'python'});
    };
    ok $@;
    like $@, qr/can't get primary columns in your query./;

    eval {
        $row->delete;
    };
    ok $@;
    like $@, qr/can't get primary columns in your query./;
};

done_testing;
