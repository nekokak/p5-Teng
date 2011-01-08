package DBIx::Skin::Util;
use strict;
use warnings;
use Class::Load ();

sub load_class {
    my $class = shift;

    return $class if Class::Load::is_class_loaded($class);

    eval "use $class"; ## no critic
    if ($@) {
        (my $file = $class) =~ s|::|/|g;
        if ($@ !~ /Can't locate $file\.pm in \@INC/) {
            die $@;
        }
        return;
    } else {
        return $class;
    }
}

sub camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

1;

