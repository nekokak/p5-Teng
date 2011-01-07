use t::Utils;
use Mock::Basic;
use Test::More;

{
    package Mock::BasicRow;
    use base qw(DBIx::Skin);

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
    use DBIx::Skin::Schema::Declare;

    table {
        name 'mock_basic_row';
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    table {
        name 'mock_basic_row_foo';
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
    use base 'DBIx::Skin::Row';

    package Mock::BasicRow::Row::MockBasicRow;
    use strict;
    use warnings;
    use base 'DBIx::Skin::Row';

    sub foo {
        'foo'
    }
}

{
    package Mock::ExRow;
    use base qw(DBIx::Skin);

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
    use DBIx::Skin::Schema::Declare;

    table {
        name 'mock_ex_row';
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    package Mock::ExRow::Row;
    use strict;
    use warnings;
    use base 'DBIx::Skin::Row';

    sub foo {'foo'}
}

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
   $db_basic->setup_test_db;
   $db_basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
   });

my $db_basic_row = Mock::BasicRow->new({
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
});
$db_basic_row->setup_test_db;
$db_basic_row->insert('mock_basic_row',{
    id   => 1,
    name => 'perl',
});

my $db_ex_row = Mock::ExRow->new({
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
});
$db_ex_row->setup_test_db;
$db_ex_row->insert('mock_ex_row',{
    id   => 1,
    name => 'perl',
});

subtest 'no your row class' => sub {
    my $row = $db_basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skin::Row';
    done_testing;
};

subtest 'your row class' => sub {
    my $row = $db_basic_row->single('mock_basic_row',{id => 1});
    isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
    is $row->foo, 'foo';
    is $row->id, 1;
    is $row->name, 'perl';
    done_testing;
};

subtest 'ex row class' => sub {
    my $row = $db_ex_row->single('mock_ex_row',{id => 1});
    isa_ok $row, 'Mock::ExRow::Row';
    is $row->foo, 'foo';
    done_testing;
};

subtest 'row_class specific Schema.pm' => sub {
    is +$db_basic_row->_get_row_class('key', 'mock_basic_row_foo'), 'Mock::BasicRow::FooRow';
    done_testing;
};

subtest 'handle' => sub {
    my $row = $db_basic->single('mock_basic',{id => 1});
    isa_ok $row->handle, 'Mock::Basic';
    can_ok $row->handle, 'single';
    done_testing;
};

done_testing;

