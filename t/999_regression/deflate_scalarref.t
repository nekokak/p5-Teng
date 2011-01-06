use t::Utils;
use Mock::Inflate;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Inflate->new({dbh => $dbh});
$db->setup_test_db;

subtest 'deflate scalarref' => sub {
    my $ref_val = \"'hoge'";
    my $val = $db->schema->call_deflate('name', $ref_val);
    is $ref_val, $val;

    my $row = $db->insert('mock_inflate',
        {
            id   => 1,
            name => $ref_val,
        }
    );
    isa_ok $row, 'DBIx::Skin::Row';
};

done_testing;


