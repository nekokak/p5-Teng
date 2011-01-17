use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
Mock::Basic->load_plugin('Replace');

subtest 'replace mock_basic data' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'Teng::Row';
    is $row->name, 'perl';

    my $replaced_row = $db->replace('mock_basic',{
        id   => 1,
        name => 'ruby',
    });
    isa_ok $replaced_row, 'Teng::Row';
    is $replaced_row->name, 'ruby';
};

done_testing;
