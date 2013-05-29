package Teng::Schema::Table;
use strict;
use warnings;
use Class::Accessor::Lite
    rw => [ qw(
        name
        primary_keys
        columns
        escaped_columns
        sql_types
        row_class
        base_row_class
    ) ]
;
use Carp ();
use Class::Load ();

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        deflators       => [],
        inflators       => [],
        escaped_columns => {},
        base_row_class  => 'Teng::Row',
        %args
    }, $class;

    # load row class
    my $row_class = $self->row_class;
    Class::Load::load_optional_class($row_class) or do {
        # make row class automatically
        Class::Load::load_class($self->base_row_class);
        no strict 'refs'; @{"$row_class\::ISA"} = ($self->base_row_class);
    };
    for my $col (@{$self->columns}) {
        no strict 'refs';
        unless ($row_class->can($col)) {
            *{"$row_class\::$col"} = $row_class->generate_column_accessor($col);
        }
    }
    $self->row_class($row_class);

    return $self;
}

sub get_sql_type {
    my ($self, $column_name) = @_;
    $self->sql_types->{ $column_name };
}

sub add_deflator {
    my ($self, $rule, $code) = @_;
    if ( ref $rule ne 'Regexp' ) {
        $rule = qr/^\Q$rule\E$/;
    }
    unless (ref($code) eq 'CODE') {
        Carp::croak('deflate code must be coderef.');
    }
    push @{ $self->{deflators} }, ( $rule, $code );
}

sub add_inflator {
    my ($self, $rule, $code) = @_;
    if ( ref $rule ne 'Regexp' ) {
        $rule = qr/^\Q$rule\E$/;
    }
    unless (ref($code) eq 'CODE') {
        Carp::croak('inflate code must be coderef.');
    }
    push @{ $self->{inflators} }, ( $rule, $code );
}

sub call_deflate {
    my ($self, $col_name, $col_value) = @_;
    my $rules = $self->{deflators};
    my $i = 0;
    my $max = @$rules;
    while ( $i < $max ) {
        my ($rule, $code) = @$rules[ $i, $i + 1 ];
        if ($col_name =~ /$rule/) {
            return $code->($col_value);
        }
        $i += 2;
    }
    return $col_value;
}

sub call_inflate {
    my ($self, $col_name, $col_value) = @_;
    my $rules = $self->{inflators};
    my $i = 0;
    my $max = @$rules;
    while ( $i < $max ) {
        my ($rule, $code) = @$rules[ $i, $i + 1 ];
        if ($col_name =~ /$rule/) {
            return $code->($col_value);
        }
        $i += 2;
    }
    return $col_value;
}

sub has_deflators {
    my $self = shift;
    return scalar @{ $self->{deflators} };
}

sub has_inflators {
    my $self = shift;
    return scalar @{ $self->{inflators} };
}

sub prepare_from_dbh {
    my ($self, $dbh) = @_;

    $self->escaped_columns->{$dbh->{Driver}->{Name}} ||= [
        map { \$dbh->quote_identifier($_) }
        @{$self->columns}
    ];
}

1;

__END__

=head1 NAME

Teng::Schema::Table - Teng table class.

=head1 METHODS

=over 4

=item $table = Teng::Schema::Table->new

create new Teng::Schema::Table's object.

=item $table->get_sql_type

get column SQL type.

=item $table->get_deflator

get deflate code reference.

=item $table->get_inflator

get inflate code reference.

=item $table->set_deflator

set deflate code reference.

=item $table->set_inflator

set inflate code reference.

=item $table->call_deflate

execute deflate.

=item $table->call_inflate

execute inflate.

=item $table->has_deflators()

Returns true if there are any deflators

=item $table->has_inflators();

Returns true if there are any inflators

=back
