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

1;

