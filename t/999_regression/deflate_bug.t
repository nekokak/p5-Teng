use t::Utils;
use Mock::Inflate;
use Mock::Inflate::Name;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Inflate->set_dbh($dbh);
Mock::Inflate->setup_test_db;

subtest 'scalar data bug case' => sub {
    my $name = Mock::Inflate::Name->new(name => 'perl');

    my $row = Mock::Inflate->insert('mock_inflate',{
        id   => 1,
        name => 'azumakuniyuki',
    });

    isa_ok $row, 'DBIx::Skinny::Row';
    isa_ok $row->name, 'Mock::Inflate::Name';
    is $row->name->name, 'azumakuniyuki_deflate';
};

done_testing;
