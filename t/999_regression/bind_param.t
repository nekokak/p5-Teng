use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'delete/update rows arrayref' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    Mock::Basic->insert('mock_basic',{
        id   => 2,
        name => 'perl',
    });

    is +Mock::Basic->count('mock_basic', 'id'), 2;

    my $update_count = Mock::Basic->update('mock_basic',{name => 'oCaml'}, {id => [1, 2]});
    is $update_count, 2;

    my $deleted_count = Mock::Basic->delete('mock_basic',{id => [1, 2]});
    is $deleted_count, 2;
    is +Mock::Basic->count('mock_basic', 'id'), 0;

    done_testing;
};

subtest 'delete/update rows using IN operator' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    Mock::Basic->insert('mock_basic',{
        id   => 2,
        name => 'perl',
    });

    is +Mock::Basic->count('mock_basic', 'id'), 2;

    my $update_count = Mock::Basic->update('mock_basic',{name => 'oCaml'}, {id => +{ in => [1, 2]}});
    is $update_count, 2;

    my $deleted_count = Mock::Basic->delete('mock_basic',{ id => { in => [1, 2] }});
    is $deleted_count, 2;
    is +Mock::Basic->count('mock_basic', 'id'), 0;
    done_testing;
};

subtest 'delete/update rows using LIKE operator' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    Mock::Basic->insert('mock_basic',{
        id   => 2,
        name => 'perl',
    });

    is +Mock::Basic->count('mock_basic', 'id'), 2;

    my $update_count = Mock::Basic->update('mock_basic',{name => 'oCaml'}, {name => +{ like => 'perl'}});
    is $update_count, 2;

    my $deleted_count = Mock::Basic->delete('mock_basic',{ name => { like => 'oCaml' }});
    is $deleted_count, 2;
    is +Mock::Basic->count('mock_basic', 'id'), 0;
    done_testing;
};

subtest 'delete/update rows XXX' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });

    is +Mock::Basic->count('mock_basic', 'id'), 1;

    my $update_count = Mock::Basic->update('mock_basic',{name => 'oCaml'}, {id => 1});
    is $update_count, 1;

    my $deleted_count = Mock::Basic->delete('mock_basic',{id => 1});
    is $deleted_count, 1;
    is +Mock::Basic->count('mock_basic', 'id'), 0;
    done_testing;
};

done_testing;
