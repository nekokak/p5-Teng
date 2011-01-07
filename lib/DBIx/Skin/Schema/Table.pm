package DBIx::Skin::Schema::Table;
use strict;
use Class::Accessor::Lite
    new => 1,
    rw => [ qw(
        name
        primary_keys
        columns
        row_class
    ) ]
;

sub new {
    my ($class, %args) = @_;
    my $self = bless { %args }, $class;
    if (! $self->row_class) {
        $self->row_class( 
            join('',
                map{ ucfirst $_ }
                    split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $self->name)
            )
        );
    }
    return $self;
}

1;
