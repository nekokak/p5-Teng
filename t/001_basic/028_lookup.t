use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;
Mock::Basic->load_plugin('Lookup');

subtest 'lookup method' => sub {
    $db_basic->insert('mock_basic', => +{
        id   => 1,
        name => 'perl',
    });

    my $row = $db_basic->lookup('mock_basic', +{id => 1});
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is_deeply $row->get_columns, +{
        id        => 1,
        name      => 'perl',
        delete_fg => 0,
    };
};

done_testing;

