package Mock::Basic::Schema;
use utf8;
use Teng::Schema::Declare;

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

1;

