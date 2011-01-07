use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'replace mock_basic data' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->name, 'perl';

    my $replaced_row = $db->replace('mock_basic',{
        id   => 1,
        name => 'ruby',
    });
    isa_ok $replaced_row, 'DBIx::Skin::Row';
    is $replaced_row->name, 'ruby';
};

done_testing;
