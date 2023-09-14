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

subtest 'row object is_changed' => sub {
    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'Teng::Row';
    is $row->name, 'perl';
    ok !$row->is_changed;

    $row->name('perl');
    ok !$row->is_changed;

    $row->name('ruby');
    ok $row->is_changed;
    # no update
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
    ok !$db->single('mock_basic', {id => 1001});

    $row->update({id => \'id + 1000'});
    ok !$db->single('mock_basic', {id => 1});

    my $new_row = $db->single('mock_basic', {id => 1001});
    is $new_row->name, 'ruby';
    $new_row->update({id => \'id - 1000'});
    is +$db->single('mock_basic', {id => 1})->name, 'ruby';
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

subtest 'update with where cond' => sub {
    my $row = $db->single('mock_basic',{
        id => 1,
    });
    is $row->name, 'tora';

    is $row->update({name => 'perl6'}, {name => 'tora'}), 1;
    is $row->name, 'perl6';

    my $row2 = $db->single('mock_basic', {
        id => 1,
    });
    is $row2->name, 'perl6';
};

subtest 'do not update with where cond' => sub {
    my $row = $db->single('mock_basic',{
        id => 1,
    });
    is $row->name, 'perl6';

    is $row->update({name => 'perl6'}, {name => 'tora'}), 0;
    is $row->name, 'perl6';

    my $row2 = $db->single('mock_basic', {
        id => 1,
    });
    is $row2->name, 'perl6';
};

subtest 'set original value again before update' => sub {
    my $row = $db->single('mock_basic',{
        id => 1,
    });
    is $row->name, 'perl6';

    $row->name('raku');
    ok $row->is_changed;
    is $row->name, 'raku';

    $row->name('perl6');
    ok !$row->is_changed;

    is $row->update, 0;
    is $row->name, 'perl6';
};

subtest 'set null again before update' => sub {
    $db->insert('mock_basic',{
        id   => 4,
        name => undef,
    });
    my $row = $db->single('mock_basic',{
        id => 4,
    });
    is $row->name, undef;

    # undef to undef
    $row->name(undef);
    ok !$row->is_changed;
    is $row->update, 0;

    # undef to string
    $row->name('php');
    ok $row->is_changed;
    is $row->update, 1;

    # string to undef
    $row->name(undef);
    ok $row->is_changed;
    is $row->update, 1;

};

done_testing;
