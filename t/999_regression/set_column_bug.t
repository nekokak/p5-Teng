use t::Utils;
use Mock::Inflate;
use Mock::Inflate::Name;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Inflate->new({dbh => $dbh});
$db->setup_test_db;

subtest 'set_column value un deflate bug' => sub {
    my $name = Mock::Inflate::Name->new(name => 'nihen');

    my $row = $db->insert('mock_inflate',{
        id   => 1,
        name => 'tsucchi',
        foo  => 'bar',
        bar  => 'zzz',
    });
    isa_ok $row, 'Teng::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    note explain $row->get_columns;

    $row->set_column(name => $name);
    $row->update(+{foo => 'piyo'});
    my $new_row = $row->refetch;
    note explain $new_row->get_columns;

};

done_testing;
