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
                foo  TEXT,
                bar  TEXT,
                PRIMARY KEY  (id, bar)
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
                bar       VARCHAR(32),
                PRIMARY KEY  (id, bar)
            ) ENGINE=InnoDB
        });
    } else {
        die 'unknown DBD';
    }
}

1;

