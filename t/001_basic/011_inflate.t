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
    });

    isa_ok $row, 'Teng::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';
    isa_ok $row->foo, 'Mock::Inflate::Name';
    is $row->foo->name, 'perl';
};

subtest 'update mock_inflate data' => sub {
    my $name = Mock::Inflate::Name->new(name => 'ruby');
    my $foo  = Mock::Inflate::Name->new(name => 'ruby');

    ok +$db->update('mock_inflate',{name => $name, foo => $foo},{id => 1});
    my $row = $db->single('mock_inflate',{id => 1});

    isa_ok $row, 'Teng::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'ruby';
    isa_ok $row->foo, 'Mock::Inflate::Name';
    is $row->foo->name, 'ruby';
};

subtest 'update row' => sub {
    my $row = $db->single('mock_inflate',{id => 1});
    my $name = $row->name;
    $name->name('perl');
    my $foo = $row->foo;
    $foo->name('perl');
    $row->update({ name => $name, foo => $foo });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';
    isa_ok $row->foo, 'Mock::Inflate::Name';
    is $row->foo->name, 'perl';

    my $updated = $db->single('mock_inflate',{id => 1});
    isa_ok $updated->name, 'Mock::Inflate::Name';
    is $updated->name->name, 'perl';
    isa_ok $updated->foo, 'Mock::Inflate::Name';
    is $updated->foo->name, 'perl';
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

done_testing;

