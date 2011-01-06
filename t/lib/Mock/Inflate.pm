package Mock::Inflate;
use DBIx::Skinny;

sub setup_test_db {
    my $skinny = shift;

    my $dbd = $skinny->_attributes->{driver_name};
    if ($dbd eq 'SQLite') {
        $skinny->do(q{
            CREATE TABLE mock_inflate (
                id   INT,
                name TEXT
            )
        });
    } elsif ($dbd eq 'mysql') {
        $skinny->do(
            q{DROP TABLE IF EXISTS mock_inflate}
        );
        $skinny->do(q{
            CREATE TABLE mock_inflate (
                id        INT auto_increment,
                name      TEXT,
                PRIMARY KEY  (id)
            ) ENGINE=InnoDB
        });
    } else {
        die 'unknown DBD';
    }
}

1;

