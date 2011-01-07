package DBIx::Skin::Schema::Table;
use strict;
use Class::Accessor::Lite
    new => 1,
    rw => [ qw(
        name
        primary_keys
        columns
        row_class
        triggers
    ) ]
;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        triggers => {},
        %args
    }, $class;

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

sub call_trigger {
    my ($self, $db, $trigger_name, $args) = @_;
    my $triggers = $self->triggers->{ $trigger_name } || [];
    for my $code (@$triggers) {
        $code->($db, $args, $self->name);
    }
}

1;
