use t::Utils;
use Mock::Basic;
use Test::More;

{
    package Mock::BasicRow;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_basic_row (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::BasicRow::Schema;
    use utf8;
    use DBIx::Skinny::Schema;

    install_table mock_basic_row => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    install_table mock_basic_row_foo => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
        row_class 'Mock::BasicRow::FooRow';
    };

    package Mock::BasicRow::FooRow;
    use strict;
    use warnings;
    use base 'DBIx::Skinny::Row';

    package Mock::BasicRow::Row::MockBasicRow;
    use strict;
    use warnings;
    use base 'DBIx::Skinny::Row';

    sub foo {
        'foo'
    }
}

{
    package Mock::ExRow;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_ex_row (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::ExRow::Schema;
    use utf8;
    use DBIx::Skinny::Schema;

    install_table mock_ex_row => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    package Mock::ExRow::Row;
    use strict;
    use warnings;
    use base 'DBIx::Skinny::Row';

    sub foo {'foo'}
}

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

Mock::BasicRow->setup_test_db;
Mock::BasicRow->insert('mock_basic_row',{
    id   => 1,
    name => 'perl',
});

Mock::ExRow->setup_test_db;
Mock::ExRow->insert('mock_ex_row',{
    id   => 1,
    name => 'perl',
});

subtest 'no your row class' => sub {
    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skinny::Row';
    done_testing;
};

subtest 'your row class' => sub {
    my $row = Mock::BasicRow->single('mock_basic_row',{id => 1});
    isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
    is $row->foo, 'foo';
    is $row->id, 1;
    is $row->name, 'perl';
    done_testing;
};

subtest 'ex row class' => sub {
    my $row = Mock::ExRow->single('mock_ex_row',{id => 1});
    isa_ok $row, 'Mock::ExRow::Row';
    is $row->foo, 'foo';
    done_testing;
};

subtest 'row_class specific Schema.pm' => sub {
    is +Mock::BasicRow->_get_row_class('key', 'mock_basic_row_foo'), 'Mock::BasicRow::FooRow';
    done_testing;
};

subtest 'handle' => sub {
    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row->handle, 'Mock::Basic';
    can_ok $row->handle, 'single';
    done_testing;
};

done_testing;

