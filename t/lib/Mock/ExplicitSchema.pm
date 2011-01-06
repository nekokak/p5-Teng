package Mock::ExplicitSchema;
use DBIx::Skinny 
    schema => 'Mock::ExplicitSchemaSchema';

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_explicitschema (
            id   integer,
            name text,
            delete_fg int(1) default 0,
            primary key ( id )
        )
    });
}

1;
