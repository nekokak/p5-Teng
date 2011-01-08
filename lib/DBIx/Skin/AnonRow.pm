package DBIx::Skin::AnonRow;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $args) = @_;

    my $self = bless {%$args}, $class;
    $self->{select_columns} = [keys %{$self->{row_data}}];
    return $self;
}

sub setup {
    my $self = shift;
    my $class = ref $self;

    for my $alias ( @{$self->{select_columns}} ) {
        (my $col = lc $alias) =~ s/.+\.(.+)/$1/o;
        next if $class->can($col);
        no strict 'refs';
        *{"$class\::$col"} = sub { $_[0]->get_column($col) };
    }
}

sub get_column {
    my ($self, $col) = @_;

    unless ( defined $col ) {
        Carp::croak('please specify $col for first argument');
    }

    my $row_data = $self->{row_data};
    if ( exists $row_data->{$col} ) {
        return $row_data->{$col};
    } else {
        Carp::croak("$col no selected column. SQL: " . ( $self->{sql} || 'unknown' ) );
    }
}

sub get_columns {
    my $self = shift;

    my %data;
    for my $col ( @{$self->{select_columns}} ) {
        $data{$col} = $self->get_column($col);
    }
    return \%data;
}

1;
