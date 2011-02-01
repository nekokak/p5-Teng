package Mock::Inflate;
use strict;
use parent qw/Teng/;

sub setup_test_db {
    my $teng = shift;

    my $dbd = $teng->{driver_name};
    if ($dbd eq 'SQLite') {
        $teng->do(q{
            CREATE TABLE mock_inflate (
                id   INT,
                name TEXT,
                foo  TEXT
            )
        });
    } elsif ($dbd eq 'mysql') {
        $teng->do(
            q{DROP TABLE IF EXISTS mock_inflate}
        );
        $teng->do(q{
            CREATE TABLE mock_inflate (
                id        INT auto_increment,
                name      TEXT,
                foo       TEXT,
                PRIMARY KEY  (id)
            ) ENGINE=InnoDB
        });
    } else {
        die 'unknown DBD';
    }
}

1;

