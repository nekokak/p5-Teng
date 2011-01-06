package Mock::ErrRowChild;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_err_child_row (
            id   INT,
            name TEXT
        )
    });
}

1;

