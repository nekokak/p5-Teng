package Mock::Basic::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_basic => schema {
    pk 'id';
    columns qw/
        id
        name
        delete_fg
    /;
};

1;

