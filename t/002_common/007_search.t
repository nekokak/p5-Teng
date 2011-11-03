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
    name => 'python',
});
$db->insert('mock_basic',{
    id   => 3,
    name => 'java',
});

subtest 'search' => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'search without where' => sub {
    my $itr = $db->search('mock_basic');

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl';

    my $row2 = $itr->next;

    isa_ok $row2, 'Teng::Row';

    is $row2->id, 2;
    is $row2->name, 'python';
};

subtest 'search with order_by (originally)' => sub {
    my $itr = $db->search('mock_basic', {}, { order_by => [ { id => 'desc' } ] });
    isa_ok $itr, 'Teng::Iterator';
    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id, 3;
    is $row->name, 'java';
};

subtest 'search with order_by (as hashref)' => sub {
    my $itr = $db->search('mock_basic', {}, { order_by => { id => 'desc' } });
    isa_ok $itr, 'Teng::Iterator';
    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id, 3;
    is $row->name, 'java';
};

subtest 'search with order_by (as string)' => sub {
    my $itr = $db->search('mock_basic', {}, { order_by => 'name' });
    isa_ok $itr, 'Teng::Iterator';
    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id, 3;
    is $row->name, 'java';
};

subtest 'search with non-exist table' => sub {
    eval {
        my $itr = $db->search('must_not_exist', {}, { order_by => 'name' });
    };
    ok $@;
    like $@, qr/No such table must_not_exist/;
};

subtest 'search with select' => sub {
    my $r = $db->single('mock_basic', {}, { columns => ['name', \'id * 2 as double_id'], order_by => ['id'] });
    is $r->name, 'perl';
    is $r->get_column('double_id'), 2;
};

done_testing;
