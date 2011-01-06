use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'get_column' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';

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
    like $@, qr/bazbaz no selected column. SQL: unknown/;
};

subtest 'get_column' => sub {
    my $row = Mock::Basic->search_by_sql(
        q{SELECT id FROM mock_basic LIMIT 1}
    )->first;
    isa_ok $row, 'DBIx::Skinny::Row';

    eval {
        $row->get_column('name');
    };
    ok $@;
    like $@, qr/name no selected column. SQL: SELECT id FROM mock_basic LIMIT 1/;
};

done_testing;

