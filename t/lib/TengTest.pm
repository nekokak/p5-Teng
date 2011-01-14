package TengTest;
use strict;
use parent qw(Teng);

sub prepare_db {
    my ( $class, $dbh ) = @_;

    my $driver = lc $dbh->{Driver}->{Name};
    my $method = "create_$driver";
    my $code   = $class->can( $method );
    if ( ! $code ) {
        die "$class: Don't know how to create tables for driver '$driver'";
    }
    $code->( $class, $dbh );
}

# for backward compatibility.
# remove this method later.
sub setup_test_db {
    my $self = shift;
    $self->prepare_db($self->dbh);
}

1;
