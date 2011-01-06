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

subtest 'resultset' => sub {
    my $rs = Mock::Basic->resultset;
    isa_ok $rs, 'DBIx::Skinny::SQL';

    $rs->add_select('name');
    $rs->from(['mock_basic']);
    $rs->add_where(id => 1);

    my $itr = $rs->retrieve;
    
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';

    is $row->name, 'perl';
};

subtest 'no connection test' => sub {
    eval {
        Mock::Basic->_attributes->{dbd} = '';
        Mock::Basic->resultset;
    };
    ok $@;
    like $@, qr/Attribute 'dbd' is not defined. Either we failed to connect, or the connection has gone away./;
};

done_testing;
