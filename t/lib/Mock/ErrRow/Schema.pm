package Mock::ErrRow::Schema;
use utf8;
use DBIx::Skin::Schema;

install_table mock_err_row => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

