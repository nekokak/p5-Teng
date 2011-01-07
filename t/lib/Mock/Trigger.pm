package Mock::Trigger;
use strict;
use base qw(DBIx::SkinTest);

sub create_sqlite {
    my ($class, $dbh) = @_;
    $dbh->do(q{
        CREATE TABLE mock_trigger_pre (
            id   INT,
            name TEXT
        )
    });
    $dbh->do(q{
        CREATE TABLE mock_trigger_post (
            id   INT,
            name TEXT
        )
    });
    $dbh->do(q{
        CREATE TABLE mock_trigger_post_delete (
            id   INT,
            name TEXT
        )
    });
}

sub create_mysql {
    my ($class, $dbh) = @_;
    $dbh->do(
        q{DROP TABLE IF EXISTS mock_trigger_pre}
    );
    $dbh->do(
        q{DROP TABLE IF EXISTS mock_trigger_post}
    );
    $dbh->do(
        q{DROP TABLE IF EXISTS mock_trigger_post_delete}
    );
    $dbh->do(q{
        CREATE TABLE mock_trigger_pre (
            id        INT auto_increment,
            name      TEXT,
            PRIMARY KEY  (id)
        ) ENGINE=InnoDB
    });
    $dbh->do(q{
        CREATE TABLE mock_trigger_post (
            id        INT auto_increment,
            name      TEXT,
            PRIMARY KEY  (id)
        ) ENGINE=InnoDB
    });
    $dbh->do(q{
        CREATE TABLE mock_trigger_post_delete (
            id        INT auto_increment,
            name      TEXT,
            PRIMARY KEY  (id)
        ) ENGINE=InnoDB
    });
}

1;

