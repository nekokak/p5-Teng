use t::Utils;
use Mock::Inflate;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Inflate->set_dbh($dbh);
Mock::Inflate->setup_test_db;

subtest 'deflate scalarref' => sub {
    my $ref_val = \"'hoge'";
    my $val = Mock::Inflate->schema->call_deflate('name', $ref_val);
    is $ref_val, $val;

    my $row = Mock::Inflate->insert('mock_inflate',
        {
            id   => 1,
            name => $ref_val,
        }
    );
    isa_ok $row, 'DBIx::Skinny::Row';
};

done_testing;


