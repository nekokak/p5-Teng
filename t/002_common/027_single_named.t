use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'single_named' => sub {
    my $row = $db->single_named('SELECT * from mock_basic where id = :id', {id => 1}, 'mock_basic');
    isa_ok $row, 'Teng::Row';
    is $row->id, 1;
    is $row->name, 'perl';
};

done_testing;
