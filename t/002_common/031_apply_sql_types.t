use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;
use JSON::XS;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic_sql_types',{
    id   => 1,
    name => 'perl',
    delete_fg => 1,
});
$db->insert('mock_basic_sql_types',{
    id   => 2,
    name => 'ruby',
    delete_fg => 0,
});
$db->insert('mock_basic_sql_types',{
    id   => 3,
    name => 4,
    delete_fg => 1,
});

sub isnum ($) {
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1
}

sub isbool {
    my ($db, $bool) = @_;
    if ($bool) {
        $bool == $db->{boolean_value}->{true};
    } else {
        $bool == $db->{boolean_value}->{false};
    }
}

subtest 'search_no_sql_types' => sub {
    my $itr = $db->search('mock_basic_sql_types');
    isa_ok $itr, 'Teng::Iterator';

    my $driver_name = $db->dbh->{Driver}->{Name};
    if ($driver_name ne 'mysql') {
        while (my $row = $itr->next) {
            isa_ok $row, 'Teng::Row';
            is isnum($row->id), 1, "is num($driver_name)";
            is isnum($row->name), 0, "is string($driver_name)";
            is isnum($row->delete_fg), 1, "is num($driver_name)";
        }
    } else {
        while (my $row = $itr->next) {
            isa_ok $row, 'Teng::Row';
            is isnum($row->name), 0, "is string";
        }
    }
};

subtest 'search_apply_sql_types_itr' => sub {
    my $itr = $db->search('mock_basic_sql_types');
    isa_ok $itr, 'Teng::Iterator';

    $itr->apply_sql_types(1);
    while (my $row = $itr->next) {
        isa_ok $row, 'Teng::Row';
        is isnum($row->name), 0, "is string";
        is isbool($db, $row->delete_fg), 1, "is bool";
    }
};

subtest 'search_apply_sql_types_db' => sub {
    $db->apply_sql_types(1);
    my $itr = $db->search('mock_basic_sql_types');
    isa_ok $itr, 'Teng::Iterator';

    while (my $row = $itr->next) {
        isa_ok $row, 'Teng::Row';
        is isnum($row->name), 0, "is string";
        is isbool($db, $row->delete_fg), 1, "is bool";
    }
};

subtest 'search_apply_sql_types_boolean' => sub {
    $db->set_boolean_value(JSON::XS::true, JSON::XS::false);
    my $itr = $db->search('mock_basic_sql_types');
    isa_ok $itr, 'Teng::Iterator';

    while (my $row = $itr->next) {
        isa_ok $row, 'Teng::Row';
        is isnum($row->name), 0, "is string";
        is isbool($db, $row->delete_fg), 1, "is bool";
        like ref $row->delete_fg, qr{^JSON::.+Boolean}, "is JSON::* object";
    }
};

subtest 'count' => sub {
    my $itr = $db->search_by_sql('select count(*) as cnt from mock_basic_sql_types');
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    my $driver_name = $db->dbh->{Driver}->{Name};
    if ($driver_name ne 'mysql') {
        is isnum($row->cnt), 1, "is num($driver_name)";
    }
};

subtest 'count_with_guess_sql_type' => sub {
    $db->guess_sql_types(1);
    my $itr = $db->search_by_sql('select count(*) as cnt from mock_basic_sql_types');
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    my $driver_name = $db->dbh->{Driver}->{Name};
    is isnum($row->cnt), 1, 'is num';
};


done_testing;
