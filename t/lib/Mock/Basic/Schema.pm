package Mock::Basic::Schema;
use utf8;
use Teng::Schema::Declare;
use DBI qw(:sql_types);

table {
    name 'mock_basic';
    pk 'id';
    columns qw/
        id
        name
        delete_fg
    /;
};

table {
    name 'mock_basic_camelcase';
    pk 'Id';
    columns qw/
        Id
        Name
        DeleteFg
    /;
};

table {
    name 'mock_basic_anotherpkey';
    pk 'table_id';
    columns qw/
        table_id
        name
        delete_fg
    /;
};

table {
    name 'mock_basic_sql_types';
    pk 'id';
    columns(
        {name => 'id'       , type => SQL_INTEGER},
        {name => 'name'     , type => SQL_VARCHAR},
        {name => 'delete_fg', type => SQL_BOOLEAN},
    );
};

1;

