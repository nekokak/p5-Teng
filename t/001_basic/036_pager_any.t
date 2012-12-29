use lib qw(t/lib);
use t::Utils;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
Mock::Basic->load_plugin('Pager::Any', {pager_classes => ['Pager', 'Count', '+Mock::Pager']});

for my $i (1..32) {
    $db->insert(mock_basic => { id => $i, name => 'name_'.$i });
}

my %pager_option = (
                    ''             => [{}, {pager_class => 'Count'}],
                    'Pager'        => [{}, {pager_class => 'Count'}],
                    'Count'        => [{pager_class => 'Pager'}, {}],
                    '+Mock::Pager' => [{pager_class => 'Pager'}, {}],
                   );

my $pager_options;
sub simple_pager_test {
    my ($db, $pager_class, $pager_options) = @_;

    # copy from 001_basic/025_pager.t
    subtest 'simple' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 1, %{$pager_options->[0]}});
        is join(',', map { $_->id } @$rows), '1,2,3';
        is $pager->entries_per_page(), 3;
        is $pager->entries_on_this_page(), 3;
        is $pager->current_page(), 1;
        is $pager->next_page, 2, 'next_page';
        ok $pager->has_next, 'has_next';
        is $pager->prev_page, undef;
    };

    subtest 'last' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 11, %{$pager_options->[0]}});
        is join(',', map { $_->id } @$rows), '31,32';
        is $pager->entries_per_page(), 3;
        is $pager->entries_on_this_page(), 2;
        is $pager->current_page(), 11;
        is $pager->next_page, undef, 'next_page';
        ok !$pager->has_next, 'has_next';
        is $pager->prev_page, 10;
    };

    subtest 'simple_with_columns' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {columns => [qw/id/], rows => 3, page => 1, %{$pager_options->[0]}});
        is join(',', map { $_->id } @$rows), '1,2,3';
        is_deeply $rows->[0]->get_columns, +{ id => 1 };
        is_deeply $rows->[1]->get_columns, +{ id => 2 };
        is_deeply $rows->[2]->get_columns, +{ id => 3 };
        is $pager->entries_per_page(), 3;
        is $pager->entries_on_this_page(), 3;
        is $pager->current_page(), 1;
        is $pager->next_page, 2, 'next_page';
        ok $pager->has_next, 'has_next';
        is $pager->prev_page, undef;
    };
    subtest 'simple_with_+columns' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {'+columns' => [\'id+20 as calc'], rows => 3, page => 1, %{$pager_options->[0]}});
        is join(',', map { $_->id } @$rows), '1,2,3';
        is join(',', map { $_->calc } @$rows), '21,22,23';
        is $pager->entries_per_page(), 3;
        is $pager->entries_on_this_page(), 3;
        is $pager->current_page(), 1;
        is $pager->next_page, 2, 'next_page';
        ok $pager->has_next, 'has_next';
        is $pager->prev_page, undef;
    };
}

sub total_pager_test {
    my ($db, $pager_class, $pager_options) = @_;

    # copy from 035_pager_count.t
    subtest 'simple' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 1, %{$pager_options->[1]}});
        is join(',', map { $_->id } @$rows), '1,2,3';
        is $pager->total_entries(), 32;
        is $pager->entries_per_page(), 3;
        is $pager->current_page(), 1;
        is $pager->next_page, 2, 'next_page';
        is $pager->previous_page, undef;
    };

    subtest 'last' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {rows => 3, page => 11, %{$pager_options->[1]}});
        is join(',', map { $_->id } @$rows), '31,32';
        is $pager->total_entries(), 32;
        is $pager->entries_per_page(), 3;
        is $pager->current_page(), 11;
        is $pager->next_page, undef, 'next_page';
        is $pager->previous_page, 10;
    };

    subtest 'simple_with_columns' => sub {
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {columns => [qw/id/], rows => 3, page => 1, %{$pager_options->[1]}});
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
        my ($rows, $pager) = $db->search_with_pager(mock_basic => {}, {'+columns' => [\'id+20 as calc'], rows => 3, page => 1, %{$pager_options->[1]}});
        is join(',', map { $_->id } @$rows), '1,2,3';
        is join(',', map { $_->calc } @$rows), '21,22,23';
        is $pager->total_entries(), 32;
        is $pager->entries_per_page(), 3;
        is $pager->current_page(), 1;
        is $pager->next_page, 2, 'next_page';
        is $pager->previous_page, undef;
    };
}

foreach my $pager_class ('', 'Pager', 'Count', '+Mock::Pager') {
    my $pager_options = $pager_option{$pager_class};

    if ($pager_class) {
        $db->pager_class($pager_class);
    }

    simple_pager_test($db, $pager_class, $pager_options);
    total_pager_test($db, $pager_class, $pager_options);

}

is_deeply [values %Mock::Pager::cache], [32];

# default pager class is changed
Mock::Basic->load_plugin('Pager::Any', {pager_classes => ['+Mock::Pager']});
undef %Mock::Pager::cache;
total_pager_test($db, '', [{}, {}]);
is_deeply [values %Mock::Pager::cache], [32];

done_testing;

