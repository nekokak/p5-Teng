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

    # multiple key
    $row = $db_basic->lookup('mock_basic', +{id => 1, name => 'perl'});
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is_deeply $row->get_columns, +{
        id        => 1,
        name      => 'perl',
        delete_fg => 0,
    };
    $row->delete;
};

subtest 'lookup method(arrayref)' => sub {
    $db_basic->insert('mock_basic', => {
        id   => 1,
        name => 'perl',
    });

    my $row = $db_basic->lookup('mock_basic', [id => 1]);
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is_deeply $row->get_columns, +{
        id        => 1,
        name      => 'perl',
        delete_fg => 0,
    };

    # multiple key
    $row = $db_basic->lookup('mock_basic', [id => 1, name => 'perl']);
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is_deeply $row->get_columns, +{
        id        => 1,
        name      => 'perl',
        delete_fg => 0,
    };
    $row->delete;
};

subtest 'lookup_with_columns' => sub {
    $db_basic->insert('mock_basic', => +{
        id   => 2,
        name => 'ruby',
    });

    my $row = $db_basic->lookup('mock_basic', +{id => 2}, { columns => [qw/id/]});
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is_deeply $row->get_columns, +{
        id => 2,
    };
};
subtest 'lookup_with_+columns' => sub {
    $db_basic->insert('mock_basic', => +{
        id   => 3,
        name => 'python',
    });

    my $row = $db_basic->lookup('mock_basic', +{id => 3}, { '+columns' => [\'id+20 as calc']});
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is_deeply $row->get_columns, +{
        id        => 3,
        name      => 'python',
        calc      => 23,
        delete_fg => 0,
    };
};

done_testing;

