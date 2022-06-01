use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Inflate;
use Mock::Inflate::Name;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Inflate->new({dbh => $dbh});
$db->setup_test_db;

subtest 'insert mock_inflate data' => sub {
    my $name = Mock::Inflate::Name->new(name => 'perl');

    my $row = $db->insert('mock_inflate',{
        id   => 1,
        name => $name,
        foo  => $name,
        bar  => $name,
    });

    isa_ok $row, 'Teng::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';
    isa_ok $row->foo, 'Mock::Inflate::Name';
    is $row->foo->name, 'perl';;
    isa_ok $row->bar, 'Mock::Inflate::Name';
    is $row->bar->name, 'perl';
};

subtest 'update mock_inflate data' => sub {
    my $name = Mock::Inflate::Name->new(name => 'ruby');
    my $foo  = Mock::Inflate::Name->new(name => 'ruby');
    my $bar  = Mock::Inflate::Name->new(name => 'ruby');

    ok +$db->update('mock_inflate',{name => $name, foo => $foo, bar => $bar},{id => 1});
    my $row = $db->single('mock_inflate',{id => 1});

    isa_ok $row, 'Teng::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'ruby';
    isa_ok $row->foo, 'Mock::Inflate::Name';
    is $row->foo->name, 'ruby';
    isa_ok $row->bar, 'Mock::Inflate::Name';
    is $row->bar->name, 'ruby';
};

subtest 'update row' => sub {
    my $row = $db->single('mock_inflate',{id => 1});
    my $name = $row->name;
    $name->name('perl');
    my $foo = $row->foo;
    $foo->name('perl');
    my $bar = $row->bar;
    $bar->name('perl');

    $row->update({ name => $name, foo => $foo, bar => $bar });

    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';
    isa_ok $row->foo, 'Mock::Inflate::Name';
    is $row->foo->name, 'perl';
    isa_ok $row->bar, 'Mock::Inflate::Name';
    is $row->bar->name, 'perl';

    my $updated = $db->single('mock_inflate',{id => 1});
    isa_ok $updated->name, 'Mock::Inflate::Name';
    is $updated->name->name, 'perl';
    isa_ok $updated->foo, 'Mock::Inflate::Name';
    is $updated->foo->name, 'perl';
    isa_ok $updated->bar, 'Mock::Inflate::Name';
    is $updated->bar->name, 'perl';


    subtest 'set_column & update' => sub  {
        my $name = Mock::Inflate::Name->new(name => 'python');
        $row->set(name => $name);
        ok $row->is_changed;
        isa_ok $row->name, 'Mock::Inflate::Name';
        is $row->name->name, 'python';
        $row->update;
        ok !$row->is_changed;

        my $updated = $db->single('mock_inflate',{id => 1});
        isa_ok $updated->name, 'Mock::Inflate::Name';
        is $updated->name->name, 'python';
    };
};

subtest 'update row twice case' => sub {
    my $row = $db->single('mock_inflate',{id => 1});
    my $name = $row->name;
    $name->name('perl');
    $row->update({ name => $name });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';

    # twice update!
    $row->update({id => 1});

    # if name is row_data then incorrect
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';
};

subtest 'insert/update on non existent table' => sub {
    eval {
        my $name = Mock::Inflate::Name->new(name => 'perl');
        my $row = $db->insert('mock_inflate_non_existent1',{
            id   => 1,
            name => $name,
            foo  => $name,
            bar  => $name,
        });
    };
    like $@, qr/Table definition for mock_inflate_non_existent1 does not exist \(Did you declare it in our schema\?\)/;

    eval {
        my $name = Mock::Inflate::Name->new(name => 'perl');
        my $row = $db->update('mock_inflate_non_existent2',{
            id   => 1,
            name => $name,
            foo  => $name,
            bar  => $name,
        });
    };
    like $@, qr/Table definition for mock_inflate_non_existent2 does not exist \(Did you declare it in our schema\?\)/;
};

subtest 'update column name' => sub {
    local $db->{force_deflate_set_column} = 1;

    # set method
    {
        my $row = $db->single('mock_inflate',{id => 1});
        $row->set(hash => { x => 'foo' });
        $row->update;
        is ref($row->hash), 'HASH';
        is $row->hash->{x}, 'foo';
    }
    {
        my $row = $db->single('mock_inflate',{id => 1});
        is ref($row->hash), 'HASH';
        is $row->hash->{x}, 'foo';
    }

    # column name
    {
        my $row = $db->single('mock_inflate',{id => 1});
        $row->hash({ x => 'foo' });
        $row->update;
        is ref($row->hash), 'HASH';
        is $row->hash->{x}, 'foo';
    }
    {
        my $row = $db->single('mock_inflate',{id => 1});
        is ref($row->hash), 'HASH';
        is $row->hash->{x}, 'foo';
    }

    # column name (update by same object)
    {
        my $row = $db->single('mock_inflate',{id => 1});
        $row->hash({ x => 'foo' });
        $row->update;
        is ref($row->hash), 'HASH';
        is $row->hash->{x}, 'foo';
    }
    {
        my $row = $db->single('mock_inflate',{id => 1});
        my $hash = $row->hash;
        $hash->{x} = 'bar';
        $row->update;
        is ref($row->hash), 'HASH';
        is $row->hash->{x}, 'bar';
    }
};

done_testing;

