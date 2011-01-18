package Teng::Schema::Table;
use strict;
use warnings;
use Class::Accessor::Lite
    rw => [ qw(
        name
        primary_keys
        columns
        sql_types
        row_class
    ) ]
;
use Carp ();
use Class::Load ();

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        %args
    }, $class;

    # load row class
    my $row_class = $self->row_class;
    Class::Load::load_optional_class($row_class) or do {
        # make row class automatically
        no strict 'refs'; @{"$row_class\::ISA"} = ('Teng::Row');
    };
    for my $col (@{$self->columns}) {
        no strict 'refs';
        unless ($row_class->can($col)) {
            *{"$row_class\::$col"} = $row_class->_lazy_get_data($col);
        }
    }
    $self->row_class($row_class);

    return $self;
}

sub get_sql_type {
    my ($self, $column_name) = @_;
    $self->sql_types->{ $column_name };
}

sub get_deflator { $_[0]->{deflators}->{$_[1]} }
sub get_inflator { $_[0]->{inflators}->{$_[1]} }
sub set_deflator {
    my ($self, $col, $code) = @_;

    unless (ref($code) eq 'CODE') {
        Carp::croak('deflate code must be coderef.');
    }
    $self->{deflators}->{$col} = $code;
}
sub set_inflator {
    my ($self, $col, $code) = @_;

    unless (ref($code) eq 'CODE') {
        Carp::croak('deflate code must be coderef.');
    }
    $self->{inflators}->{$col} = $code;
}

sub call_deflate {
    my ($self, $col_name, $col_value) = @_;
    if (my $code = $self->get_deflator( $col_name )) {
        return $code->($col_value);
    }
    return $col_value;
}

sub call_inflate {
    my ($self, $col_name, $col_value) = @_;
    if (my $code = $self->get_inflator( $col_name )) {
        return $code->($col_value);
    }
    return $col_value;
}

1;

__END__

=head1 NAME

Teng::Schema::Table - Teng table class.

=head1 METHODS

=over 4

=item $table = Teng::Table->new

create new Teng::Table's object.

=item $table->get_sql_type

get column SQL type.

=item $table->get_deflator

get deflate coderef.

=item $table->get_inflator

get inflate coderef.

=item $table->set_deflator

set deflate coderef.

=item $table->set_inflator

set inflate coderef.

=item $table->call_deflate

execute deflate.

=item $table->call_inflate

execute inflate.

=back
