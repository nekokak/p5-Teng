package Mock::Basic;
use DBIx::Skinny;

sub setup_test_db {
    my $skinny = shift;

    my $dbd = $skinny->_attributes->{driver_name};
    if ($dbd eq 'SQLite') {
        $skinny->do(q{
            CREATE TABLE mock_basic (
                id   integer,
                name text,
                delete_fg int(1) default 0,
                primary key ( id )
            )
        });
    } elsif ($dbd eq 'mysql') {
        $skinny->do(
            q{DROP TABLE IF EXISTS mock_basic}
        );
        $skinny->do(q{
            CREATE TABLE mock_basic (
                id        INT auto_increment,
                name      TEXT,
                delete_fg TINYINT(1) default 0,
                PRIMARY KEY  (id)
            ) ENGINE=InnoDB
        });
    } elsif ($dbd eq 'Pg') {
        $skinny->do(
            q{DROP TABLE IF EXISTS mock_basic}
        );
        $skinny->do(q{
            CREATE TABLE mock_basic (
                id   SERIAL PRIMARY KEY,
                name TEXT,
                delete_fg boolean
            )
        });
    } else {
        die 'unknown DBD';
    }
}

1;

