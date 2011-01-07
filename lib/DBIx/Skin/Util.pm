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

sub mk_row_class {
    my ($class, $table) = @_;

    (my $k = $class) =~ s/::Schema//;
    my $r = join '::', $k, 'Row', camelize($table);
    load_class($r) or do {
        my $isa_row = DBIx::Skin::Util::load_class(join '::', $k, 'Row') || 'DBIx::Skin::Row';
        {no strict 'refs'; @{"$r\::ISA"} = ($isa_row)}
        $r;
    };
}

1;

