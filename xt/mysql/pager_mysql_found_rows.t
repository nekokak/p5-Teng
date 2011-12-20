use t::Utils;
use xt::Utils::mysql;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
Mock::Basic->load_plugin('Pager::MySQLFoundRows');

for my $i (1..32) {
    $db->insert(mock_basic => { id => $i, name => 'name_'.$i });
}

subtest 'simple' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 1});
    is join(',', map { $_->id } @$rows), '1,2,3';
    is $pager->total_entries(), 32;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    is $pager->previous_page, undef;
};

subtest 'last' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 11});
    is join(',', map { $_->id } @$rows), '31,32';
    is $pager->total_entries(), 32;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 11;
    is $pager->next_page, undef, 'next_page';
    is $pager->previous_page, 10;
};

subtest 'simple_with_columns' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {columns => [qw/id/], rows => 3, page => 1});
    is join(',', map { $_->id } @$rows), '1,2,3';
    is_deeply $rows->[0]->get_columns, +{ id => 1 };
    is_deeply $rows->[1]->get_columns, +{ id => 2 };
    is_deeply $rows->[2]->get_columns, +{ id => 3 };
    is $pager->total_entries(), 32;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    is $pager->previous_page, undef;
};
subtest 'simple_with_+columns' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {'+columns' => [\'id+20 as calc'], rows => 3, page => 1});
    is join(',', map { $_->id } @$rows), '1,2,3';
    is join(',', map { $_->calc } @$rows), '21,22,23';
    is $pager->total_entries(), 32;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    is $pager->previous_page, undef;
};

done_testing;


