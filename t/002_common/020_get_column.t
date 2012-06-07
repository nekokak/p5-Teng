use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'get_column' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'Teng::Row';

    is($row->get_column('name') => 'perl', 'get_column ok');

    eval {
        $row->get_column;
    };
    ok $@;
    like $@, qr/please specify \$col for first argument/;

    eval {
        $row->get_column('bazbaz'); 
    };
    ok $@;
    like $@, qr/Specified column 'bazbaz' not found in row/;
};

subtest 'get_column' => sub {
    my $row = $db->search_by_sql(
        q{SELECT id FROM mock_basic LIMIT 1}
    )->next;
    isa_ok $row, 'Teng::Row';

    eval {
        $row->get_column('name');
    };
    ok $@;
    like $@, qr/Specified column 'name' not found in row \(query: SELECT id FROM mock_basic LIMIT 1\)/;
};

done_testing;

