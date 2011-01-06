package DBIx::Skinny::DBD;
use strict;
use warnings;
use Carp ();

sub new {
    my ($class, $dbd_type) =@_;
    Carp::confess "No Driver" unless $dbd_type;

    my $subclass = join '::', $class, $dbd_type;
    eval "use $subclass"; ## no critic
    Carp::confess $@ if $@;
    bless {}, $subclass;
}

1;

