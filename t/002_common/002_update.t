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

subtest 'update mock_basic data' => sub {
    ok $db->update('mock_basic',{name => 'python'},{id => 1});
    my $row = $db->single('mock_basic',{id => 1});

    isa_ok $row, 'Teng::Row';
    is $row->name, 'python';
};

subtest 'row object update' => sub {
    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'Teng::Row';
    is $row->name, 'python';

    ok $row->update({name => 'perl'});
    is $row->name, 'perl';
    my $new_row = $db->single('mock_basic',{id => 1});
    is $new_row->name, 'perl';
};

subtest 'row data set and update' => sub {
    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'Teng::Row';
    is $row->name, 'perl';

    $row->set_columns({name => 'ruby'});

    is $row->name, 'ruby';

    my $row2 = $db->single('mock_basic',{id => 1});
    is $row2->name, 'perl';

    ok $row->update;
    my $new_row = $db->single('mock_basic',{id => 1});
    is $new_row->name, 'ruby';
};

subtest 'scalarref update' => sub {
    my $row = $db->single('mock_basic',{id => 1});
    is $row->name, 'ruby';

    ok $row->update({name => '1'});
    my $new_row = $db->single('mock_basic',{id => 1});
    is $new_row->name, '1';

    $new_row->update({name => \'name + 1'});

    is +$db->single('mock_basic',{id => 1})->name, 2;
};

subtest 'update row count' => sub {
    $db->insert('mock_basic',{
        id   => 2,
        name => 'c++',
    });

    my $cnt = $db->update('mock_basic',{name => 'java'});
    is $cnt, 2;
};

subtest 'update primary key' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 3,
        name => 'php',
    });
    $row->update({id => 999});
    ok !$db->single('mock_basic',{id => 3});

    my $new_row = $db->single('mock_basic',{id => 999});
    isa_ok $new_row, 'Teng::Row';
    is $row->id, 999;
    is $row->name, 'php';
};

subtest 'empty update' => sub {
    my $row = $db->single('mock_basic',{
        id => 1,
    });
    is $row->name, 'java';

    $row->set_column(name => 'perl');
    is $row->update, 1;
    is $row->name, 'perl';

    is $row->update, 0;
    is $row->name, 'perl';

    is $row->update({}), 0;
    is $row->name, 'perl';
};

subtest 'update by setter column' => sub {
    my $row = $db->single('mock_basic',{
        id => 1,
    });
    is $row->name, 'perl';

    $row->name('tora');
    is $row->update, 1;
    is $row->name, 'tora';

    my $row2 = $db->single('mock_basic',{
        id => 1,
    });
    is $row2->name, 'tora';
};

done_testing;

