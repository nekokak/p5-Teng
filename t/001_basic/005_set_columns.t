use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'insert mode' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => 'nekokak'}, 1);

    is_deeply $cols, +['?','?'];
    is_deeply $column_list, [
        [
            'name',
            'nekokak',
        ],
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

subtest 'insert mode / scalarref' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => \'NOW ()'}, 1);

    is_deeply $cols, +[
        'NOW ()',
        '?',
    ];
    is_deeply $column_list, [
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

subtest 'update mode' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => 'nekokak'}, 0);

    is_deeply $cols, +[
        '`name` = ?',
        '`id` = ?',
    ];
    is_deeply $column_list, [
        [
            'name',
            'nekokak',
        ],
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

subtest 'update mode / scalarref' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => \'NOW()'}, 0);

    is_deeply $cols, +[
        '`name` = NOW()',
        '`id` = ?',
    ];
    is_deeply $column_list, [
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

done_testing;
