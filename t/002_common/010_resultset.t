use t::Utils;
use Mock::Basic;
use Test::More;

TODO: {
todo_skip 'not yet..',0;
my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'resultset' => sub {
    my $rs = $db->resultset;
    isa_ok $rs, 'DBIx::Skin::SQL';

    $rs->add_select('name');
    $rs->from(['mock_basic']);
    $rs->add_where(id => 1);

    my $itr = $rs->retrieve;
    
    isa_ok $itr, 'DBIx::Skin::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'DBIx::Skin::Row';

    is $row->name, 'perl';
};

subtest 'no connection test' => sub {
    eval {
        $db->{dbd} = '';
        $db->resultset;
    };
    ok $@;
    like $@, qr/Attribute 'dbd' is not defined. Either we failed to connect, or the connection has gone away./;
};

done_testing;
};
