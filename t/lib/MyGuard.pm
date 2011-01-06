package MyGuard;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $code) = @_;
    bless $code, $class;
}

sub DESTROY {
    my $self = shift;
    $self->();
}

1;

