package DBIx::Skinny::Util;
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
        my $isa_row = DBIx::Skinny::Util::load_class(join '::', $k, 'Row') || 'DBIx::Skinny::Row';
        {no strict 'refs'; @{"$r\::ISA"} = ($isa_row)}
        $r;
    };
}

sub utf8_on {
    if ($] <= 5.008000) {
        require Encode;
        return sub {
            my ($class, $col, $data) = @_;
            if ($class->is_utf8_column($col)) {
                Encode::_utf8_on($data) unless Encode::is_utf8($data);
            }
            $data;
        };
    } else {
        require utf8;
        return sub {
            my ($class, $col, $data) = @_;
            if ($class->is_utf8_column($col)) {
                utf8::decode($data) unless utf8::is_utf8($data);
            }
            $data;
        };
    }
}

sub utf8_off {
    if ($] <= 5.008000) {
        require Encode;
        return sub {
            my ($class, $col, $data) = @_;
            if ($class->is_utf8_column($col)) {
                Encode::_utf8_off($data) if Encode::is_utf8($data);
            }
            $data;
        };
    } else {
        require utf8;
        return sub {
            my ($class, $col, $data) = @_;
            if ($class->is_utf8_column($col)) {
                utf8::encode($data) if utf8::is_utf8($data);
            }
            $data;
        };
    }
}


1;

