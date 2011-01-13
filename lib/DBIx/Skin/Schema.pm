package DBIx::Skin::Schema;
use strict;
use warnings;
use DBIx::Skin::Row ();
use Class::Accessor::Lite
    rw => [ qw(
        tables
    ) ]
;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
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
    return unless $name;
    $self->tables->{$name};
}

sub get_row_class {
    my ($self, $table_name) = @_;

    my $table = $self->get_table($table_name);
    if ($table) {
        return $table->row_class;
    } else {
        return 'DBIx::Skin::Row';
    }
}

sub call_deflate {
    my ($self, $table_name, $col_name, $col_value) = @_;
    my $table = $self->get_table($table_name)
        or Carp::croak("No table object associated with '$table_name'");
    $table->call_deflate($col_name, $col_value);
}

sub call_inflate {
    my ($self, $table_name, $col_name, $col_value) = @_;
    my $table = $self->get_table($table_name);
    $table->call_inflate($col_name, $col_value);
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


