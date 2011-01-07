package Mock::Basic::Schema;
use utf8;
use DBIx::Skin::Schema::Declare;

table {
    name 'mock_basic';
    pk 'id';
    columns qw/
        id
        name
        delete_fg
    /;
};

1;

