package DBIx::Skin::Schema::Table;
use strict;
use Class::Accessor::Lite
    rw => [ qw(
        name
        primary_keys
        columns
        sql_types
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
        # camelize the table name
        $self->row_class( 
            join('',
                map{ ucfirst $_ }
                    split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $self->name)
            )
        );
    }
    return $self;
}

sub add_trigger {
    my ($self, $trigger_name, $callback) = @_;
    my $triggers = $self->triggers->{ $trigger_name } || [];
    push @$triggers, $callback;
}

sub call_trigger {
    my ($self, $db, $trigger_name, $args) = @_;
    my $triggers = $self->triggers->{ $trigger_name } || [];
    for my $code (@$triggers) {
        $code->($db, $args, $self->name);
    }
}

sub get_sql_type {
    my ($self, $column_name) = @_;
    $self->sql_types->{ $column_name };
}

1;
