package DBIx::Skin::Schema;
use strict;
use warnings;
use Scalar::Util ();
use DBIx::Skin::Util ();
use DBIx::Skin::Row ();
use Class::Accessor::Lite
    rw => [ qw(
        tables
        triggers
    ) ]
;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        triggers => {},
        tables => {},
        %args,
    }, $class;
    return $self;
}

sub set_default_instance {
    my ($class, $instance) = @_;
    no strict 'refs';
    no warnings 'once';
    ${"$class\::DEFAULT_INSTANCE"} = $instance;
}

sub instance {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    ${"$class\::DEFAULT_INSTANCE"};
}

sub add_table {
    my ($self, $table) = @_;
    $self->tables->{$table->name} = $table;
}

sub get_table {
    my ($self, $name) = @_;
    if ( ! $name ) {
        Carp::confess( "No name provided for get_table()" );
    }
    $self->tables->{$name};
}

sub get_row_class {
    my ($self, $db, $table_name) = @_;

    my $table = $self->get_table($table_name);
    if (! $table) {
        Carp::croak( "No table object associated with $table_name" );
    }
    my $row_class = $table->row_class;

    if ( $row_class !~ s/^\+// ) {
        $row_class = join '::',
            Scalar::Util::blessed($db),
            'Row',
            $row_class
        ;
    }

    Class::Load::load_optional_class($row_class) or do {
        # make row class automatically
        no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skin::Row');
        foreach my $col (@{$table->columns}) {
            no strict 'refs';
            *{"$row_class\::$col"} = $row_class->_lazy_get_data($col);
        }
    };

    return $row_class;
}

sub add_trigger {
    my ($self, $trigger_name, $callback) = @_;
    my $triggers = $self->triggers->{ $trigger_name } || [];
    push @$triggers, $callback;
}

sub call_trigger {
    my ($self, $trigger_name, $db, $table_name, $args) = @_;

    my $triggers = $self->triggers->{ $trigger_name } || [];
    for my $code (@$triggers) {
        $code->($db, $args, $table_name);
    }

    my $table = $self->get_table($table_name);
    if (! $table) {
        Carp::croak( "No table object associated with $table_name" );
    }
    $table->call_trigger( $db, $trigger_name, $args );
}

1;

__END__

=head1 NAME

DBIx::Skin::Schema - Schema DSL for DBIx::Skin

=head1 SYNOPSIS

    package Your::Model;
    use DBIx::Skin connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    1;
    
    package Your::Model::Schema:
    use DBIx::Skin::Schema;
    
    # set user table schema settings
    install_table user => schema {
        pk 'id';
        columns qw/id name created_at/;

        trigger pre_insert => callback {
            # hook
        };

        trigger pre_update => callback {
            # hook
        };

        row_class 'Your::Model::Row::User';
    };

    install_inflate_rule '^name$' => callback {
        inflate {
            my $value = shift;
            # inflate hook
        };
        deflate {
            my $value = shift;
            # deflate hook
        };
    };
    
    1;


