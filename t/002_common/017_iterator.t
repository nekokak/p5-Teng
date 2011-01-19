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
$db->insert('mock_basic',{
    id   => 2,
    name => 'ruby',
});

subtest 'all' => sub {
    my $itr = $db->search("mock_basic");
    my $rows = $itr->all;
    is ref $rows, 'ARRAY';
    is $rows->[0]->id, 1;
};

subtest 'iterator with no cache all/count' => sub {
    my $itr = $db->search("mock_basic");
    isa_ok $itr, 'Teng::Iterator';

    my @rows = $itr->all;
    is scalar(@rows), 2, "rows count";

    ok !$itr->next, "cannot retrieve first row after count";
};

subtest 'iterator with no cache' => sub {
    my $itr = $db->search("mock_basic");
    isa_ok $itr, 'Teng::Iterator';

    my $row1 = $itr->next;
    isa_ok $row1, 'Teng::Row';
    my $row2 = $itr->next;
    isa_ok $row2, 'Teng::Row';

    ok !$itr->next, 'no more row';
};

subtest 'iterator with suppress_object_creation on to off' => sub {
    my $itr = $db->search("mock_basic");
    isa_ok $itr, 'Teng::Iterator';
    $itr->suppress_object_creation(1);

    my $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row,  {
        id        => 1,
        delete_fg => 0,
        name      => 'perl',
    };

    $itr->suppress_object_creation(0);
    $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    my $dat = $row->get_columns;
    is_deeply $dat, {
          id        => 2,
          delete_fg => 0,
          name      => 'ruby',
    };
};

subtest 'iterator with suppress_row_objects on to off' => sub {
    $db->suppress_row_objects(1);
    my $itr = $db->search("mock_basic");
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row,  {
        id        => 1,
        delete_fg => 0,
        name      => 'perl',
    };

    $db->suppress_row_objects(0);
    $itr = $db->search("mock_basic");
    isa_ok $itr, 'Teng::Iterator';
    $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    my $dat = $row->get_columns;
    is_deeply $dat, {
          id        => 1,
          delete_fg => 0,
          name      => 'perl',
    };
};

subtest 'iterator with suppress_row_objects on with cache' => sub {
    $db->suppress_row_objects(1);
    my $itr = $db->search("mock_basic");
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row,  {
        id        => 1,
        delete_fg => 0,
        name      => 'perl',
    };

    $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row, {
          id        => 2,
          delete_fg => 0,
          name      => 'ruby',
    };
};

$db->suppress_row_objects(0);

done_testing;

