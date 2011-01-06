use t::Utils;
use Mock::Inflate;
use Mock::Inflate::Name;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Inflate->set_dbh($dbh);
Mock::Inflate->setup_test_db;

subtest 'insert mock_inflate data' => sub {
    my $name = Mock::Inflate::Name->new(name => 'perl');

    my $row = Mock::Inflate->insert('mock_inflate',{
        id   => 1,
        name => $name,
    });

    isa_ok $row, 'DBIx::Skinny::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';
};

subtest 'update mock_inflate data' => sub {
    my $name = Mock::Inflate::Name->new(name => 'ruby');

    ok +Mock::Inflate->update('mock_inflate',{name => $name},{id => 1});
    my $row = Mock::Inflate->single('mock_inflate',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'ruby';
};

subtest 'update row' => sub {
    my $row = Mock::Inflate->single('mock_inflate',{id => 1});
    my $name = $row->name;
    $name->name('perl');
    $row->update({ name => $name });
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'perl';

    my $updated = Mock::Inflate->single('mock_inflate',{id => 1});
    isa_ok $updated->name, 'Mock::Inflate::Name';
    is $updated->name->name, 'perl';
};

done_testing;
