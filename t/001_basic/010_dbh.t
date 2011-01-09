use t::Utils;
use Test::More;

{
    package Mock::DBH;
    use base qw(DBIx::Skin);

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
    use DBIx::Skin::Schema::Declare;

    table {
        name 'mock_dbh';
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
    my $schema = $db->schema;
    isa_ok $schema, 'Mock::DBH::Schema';
    my $table = $schema->get_table( 'mock_dbh' );

    is_deeply $table->primary_keys, [ 'id' ];
    is_deeply $table->columns, [ 'id', 'name' ];
    is $table->row_class, "Mock::DBH::Row::MockDbh";

    isa_ok +$db->dbh, 'DBI::db';
    done_testing;
};

subtest 'insert' => sub {
    $db->insert('mock_dbh',{id => 1 ,name => 'nekokak'});
    TODO : {
        todo_skip "XXX nekokak", 1;
    is +$db->count('mock_dbh','id',{name => 'nekokak'}), 1;
    };
    done_testing;
};

done_testing;
