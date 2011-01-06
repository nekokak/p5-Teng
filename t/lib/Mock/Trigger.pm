package Mock::Trigger;
use DBIx::Skinny;

sub setup_test_db {
    my $skinny = shift;

    my $dbd = $skinny->_attributes->{driver_name};
    if ($dbd eq 'SQLite') {
        $skinny->do(q{
            CREATE TABLE mock_trigger_pre (
                id   INT,
                name TEXT
            )
        });
        $skinny->do(q{
            CREATE TABLE mock_trigger_post (
                id   INT,
                name TEXT
            )
        });
        $skinny->do(q{
            CREATE TABLE mock_trigger_post_delete (
                id   INT,
                name TEXT
            )
        });
    } elsif ($dbd eq 'mysql') {
        $skinny->do(
            q{DROP TABLE IF EXISTS mock_trigger_pre}
        );
        $skinny->do(
            q{DROP TABLE IF EXISTS mock_trigger_post}
        );
        $skinny->do(
            q{DROP TABLE IF EXISTS mock_trigger_post_delete}
        );
        $skinny->do(q{
            CREATE TABLE mock_trigger_pre (
                id        INT auto_increment,
                name      TEXT,
                PRIMARY KEY  (id)
            ) ENGINE=InnoDB
        });
        $skinny->do(q{
            CREATE TABLE mock_trigger_post (
                id        INT auto_increment,
                name      TEXT,
                PRIMARY KEY  (id)
            ) ENGINE=InnoDB
        });
        $skinny->do(q{
            CREATE TABLE mock_trigger_post_delete (
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

