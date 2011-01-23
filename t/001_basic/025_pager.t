use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
# use fully qualified package name for coverage
Mock::Basic->load_plugin('+Teng::Plugin::Pager');

for my $i (1..32) {
    $db->insert(mock_basic => { id => $i, name => 'name_'.$i });
}

subtest 'simple' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 1});
    is join(',', map { $_->id } @$rows), '1,2,3';
    is $pager->entries_per_page(), 3;
    is $pager->entries_on_this_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    ok $pager->has_next, 'has_next';
    is $pager->prev_page, undef;
};

subtest 'last' => sub {
    my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 11});
    is join(',', map { $_->id } @$rows), '31,32';
    is $pager->entries_per_page(), 3;
    is $pager->entries_on_this_page(), 2;
    is $pager->current_page(), 11;
    is $pager->next_page, undef, 'next_page';
    ok !$pager->has_next, 'has_next';
    is $pager->prev_page, 10;
};

done_testing;

