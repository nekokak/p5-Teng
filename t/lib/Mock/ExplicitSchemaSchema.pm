package Mock::ExplicitSchemaSchema;
use Teng::Schema;

install_table mock_explicitschema => schema {
    pk 'id';
    columns qw/
        id
        name
        delete_fg
    /;
};

1;
