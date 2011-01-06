use t::Utils;
use Test::More;

{
    package Mock::DBH;
    use DBI;
    use DBIx::Skinny connect_info => +{
        dbh => DBI->connect('dbi:SQLite:', '', ''),
    };

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_dbh (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::DBH::Schema;
    use utf8;
    use DBIx::Skinny::Schema;

    install_table mock_dbh => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

Mock::DBH->setup_test_db;

subtest 'schema info' => sub {
    is +Mock::DBH->schema, 'Mock::DBH::Schema';

    my $info = Mock::DBH->schema->schema_info;
    is_deeply $info,{
        mock_dbh => {
            pk      => 'id',
            columns => [
                'id',
                'name',
            ],
            column_types => +{},
            row_class => 'Mock::DBH::Row::MockDbh',
        }
    };

    isa_ok +Mock::DBH->dbh, 'DBI::db';
    done_testing;
};

subtest 'insert' => sub {
    Mock::DBH->insert('mock_dbh',{id => 1 ,name => 'nekokak'});
    is +Mock::DBH->count('mock_dbh','id',{name => 'nekokak'}), 1;
    done_testing;
};

done_testing;
