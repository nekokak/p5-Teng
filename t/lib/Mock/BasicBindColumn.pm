package Mock::BasicBindColumn;
use DBIx::Skinny;

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_basic_bind_column (
            id   int,
            uid  bigint,
            name text,
            body blob,
            raw  bin,
            primary key ( id )
        )
    });
}

1;
