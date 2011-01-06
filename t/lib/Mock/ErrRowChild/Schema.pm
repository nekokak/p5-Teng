package Mock::ErrRowChild::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_err_child_row => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

