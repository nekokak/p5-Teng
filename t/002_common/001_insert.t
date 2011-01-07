use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'insert mock_basic data/ insert method' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->name, 'perl';
};

subtest 'insert mock_basic data/ create method' => sub {
    my $row = $db->create('mock_basic',{
        id   => 2,
        name => 'ruby',
    });
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->name, 'ruby';
};

done_testing;
