package DBIx::SkinTest;
use strict;
use parent qw(DBIx::Skin);

sub prepare_db {
    my ( $class, $dbh ) = @_;

    my $driver = lc $dbh->{Driver}->{Name};
    my $method = "create_$driver";
    my $code   = $class->can( $method );
    if ( ! $code ) {
        die "$class: Don't know how to create tables for driver $driver";
    }
    $code->( $class, $dbh );
}

1;
