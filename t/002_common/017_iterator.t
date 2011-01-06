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
Mock::Basic->insert('mock_basic',{
    id   => 2,
    name => 'ruby',
});

subtest 'all' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    my $rows = $itr->all;
    is ref $rows, 'ARRAY';
    is $rows->[0]->id, 1;
};

subtest 'iterator with cache' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    is $itr->position, 0, 'initial position';

    is $itr->count, 2, "rows count";
    my @rows = $itr->all;
    is scalar(@rows), 2, "all rows";
    is $itr->position, 2, 'all-last position';
    $itr->reset;
    is $itr->position, 0, 'reset position';

    my $row1 = $itr->next;
    isa_ok $row1, 'DBIx::Skinny::Row';
    is $itr->position, 1, 'one next position';
    my $row2 = $itr->next;
    isa_ok $row2, 'DBIx::Skinny::Row';
    is $itr->position, 2, 'two next position';
    ok !$itr->next, 'no more row';
    is $itr->position, 2, 'next-last position';

    ok $itr->reset, "reset ok";
    $row1 = $itr->first;
    isa_ok $row1, 'DBIx::Skinny::Row';
};

subtest 'iterator with no cache all/count' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    $itr->cache(0);

    is $itr->count, 2, "rows count";
    my @rows = $itr->all;
    is scalar(@rows), 0, "cannot retrieve all rows after count";

    ok $itr->reset, "reset ok";
    ok !$itr->first, "cannot retrieve first row after count";
};

subtest 'iterator with no cache' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    is $itr->position, 0, 'initial position';
    $itr->cache(0);

    my $row1 = $itr->next;
    isa_ok $row1, 'DBIx::Skinny::Row';
    is $itr->position, 1, 'one next position';
    my $row2 = $itr->next;
    isa_ok $row2, 'DBIx::Skinny::Row';
    is $itr->position, 2, 'two next position';

    ok !$itr->next, 'no more row';
    is $itr->position, 2, 'next-last position';
    ok $itr->reset, 'reset ok';
    is $itr->position, 0, 'reset position';
    ok !$itr->first, "cannot retrieve first row";
};

subtest 'iterator with suppress_objects on to off' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    $itr->suppress_objects(1);

    my $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row,  {
        id        => 1,
        delete_fg => 0,
        name      => 'perl',
    };

    $itr->suppress_objects(0);
    $row = $itr->next;
    isa_ok $row, 'DBIx::Skinny::Row';
    my $dat = $row->get_columns;
    is_deeply $dat, {
          id        => 2,
          delete_fg => 0,
          name      => 'ruby',
    };
};

subtest 'iterator with suppress_row_objects on to off' => sub {
    Mock::Basic->suppress_row_objects(1);
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row,  {
        id        => 1,
        delete_fg => 0,
        name      => 'perl',
    };

    Mock::Basic->suppress_row_objects(0);
    $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    $row = $itr->next;
    isa_ok $row, 'DBIx::Skinny::Row';
    my $dat = $row->get_columns;
    is_deeply $dat, {
          id        => 1,
          delete_fg => 0,
          name      => 'perl',
    };
};

subtest 'iterator with suppress_row_objects on with cache' => sub {
    Mock::Basic->suppress_row_objects(1);
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';

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

    $itr->reset;

    $row = $itr->next;
    is ref($row), 'HASH';
    is_deeply $row,  {
        id        => 1,
        delete_fg => 0,
        name      => 'perl',
    };
};

Mock::Basic->suppress_row_objects(0);

done_testing;

