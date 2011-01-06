use t::Utils;
use Test::More;

{
    package Mock::DBH;
    use DBI;
    use DBIx::Skin;

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
    use DBIx::Skin::Schema;

    install_table mock_dbh => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

my $db = Mock::DBH->new(+{dbh => DBI->connect('dbi:SQLite:', '', '')});
$db->setup_test_db;

subtest 'schema info' => sub {
    is +Mock::DBH->schema, 'Mock::DBH::Schema';

    my $info = $db->schema->schema_info;
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

    isa_ok +$db->dbh, 'DBI::db';
    done_testing;
};

subtest 'insert' => sub {
    $db->insert('mock_dbh',{id => 1 ,name => 'nekokak'});
    is +$db->count('mock_dbh','id',{name => 'nekokak'}), 1;
    done_testing;
};

done_testing;
