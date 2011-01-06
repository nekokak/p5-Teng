package # hide from PAUSE
  Sample;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
};

sub setup_db {
    shift->do(q{
        CREATE TABLE tinyurl (
            id  INT,
            url TEXT,
            tinyurl TEXT
        )
    });
}

1;
