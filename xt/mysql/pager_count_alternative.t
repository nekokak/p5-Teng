use t::Utils;
use xt::Utils::mysql;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
Mock::Basic->load_plugin('Pager::Count', {alternative_pager => 'Pager::MySQLFoundRows'});

for my $i (1..32) {
    $db->insert(mock_basic => { id => $i, name => 'name_'. sprintf('%02d', $i % 2 ? $i : $i - 1)});
}

subtest 'simple_with_group_by_alternate_pager' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {group_by => ['name'], rows => 3, page => 1, order_by => ['name']});
    is join(',', map { $_->name } @$rows), 'name_01,name_03,name_05';
    is $pager->total_entries(), 16;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    is $pager->previous_page, undef;
};

done_testing;


