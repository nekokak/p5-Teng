package DBIx::Skinny::Iterator;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Carp ();

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;
    $self->{_cache} = 1;

    $self->reset;

    return wantarray ? $self->all : $self;
}

sub iterator {
    my $self = shift;

    my $position = $self->{_position};
    if ( $self->{_cache}
      && ( my $row_cache = $self->{_rows_cache}->[$position] ) ) {
        $self->{_position} = $position + 1;
        return $row_cache;
    }

    my $row;
    if ($self->{sth}) {
        $row = $self->{sth}->fetchrow_hashref('NAME_lc');
        unless ( $row ) {
            $self->{skinny}->_close_sth($self->{sth});
            $self->{sth} = undef;
            return;
        }
    } elsif ($self->{data} && ref $self->{data} eq 'ARRAY') {
        $row = shift @{$self->{data}};
        unless ( $row ) {
            return;
        }
    } else {
        return;
    }

    my $obj;
    if ( Scalar::Util::blessed($row) ) {
        $obj = $row;
    } elsif ($self->suppress_objects) {
        $obj = $row;
    } else {
        $obj = $self->{row_class}->new(
            {
                sql            => $self->{sql},
                row_data       => $row,
                skinny         => $self->{skinny},
                opt_table_info => $self->{opt_table_info},
            }
        );

        unless ($self->{_setup}) {
            $obj->setup;
            $self->{_setup}=1;
        }
    }

    $self->{_rows_cache}->[$position] = $obj if $self->{_cache};
    $self->{_position} = $position + 1;

    return $obj;
}

sub first {
    my $self = shift;
    $self->reset;
    $self->next;
}

sub next { $_[0]->iterator }

sub all {
    my $self = shift;
    my @result;
    while ( my $row = $self->next ) {
        push @result, $row;
    }
    return wantarray ? @result : \@result;
}

sub reset {
    my $self = shift;
    $self->{_position} = 0;
    return $self;
}

sub count {
    my $self = shift;
    my $rows = $self->reset->all;
    $self->reset;
    scalar @$rows;
}

sub suppress_objects {
    my ($self, $mode) = @_;
    return $self->{suppress_objects} unless defined $mode;
    $self->{suppress_objects} = $mode;
}

sub no_cache {
    Carp::carp( "no_cache method has been deprecated. Please use cache method instead" );
    $_[0]->{_cache} = 0;
}

sub cache {
    my ($self, $mode) = @_;
    return $self->{_cache} unless defined $mode;
    $self->{_cache} = $mode;
}

sub position { $_[0]->{_position} }

1;

__END__
=head1 NAME

DBIx::Skinny::Iterator

=head1 DESCRIPTION

skinny iteration class.

=head1 SYNOPSIS

  my $itr = Your::Model->search('user',{});
  
  $itr->count; # show row counts
  
  my $row = $itr->first; # get first row
  
  $itr->reset; # reset itarator position
  
  my @rows = $itr->all; # get all rows
  
  # do iteration
  while (my $row = $itr->next) { }

  # no cache row object (save memories)
  $itr->cache(0);
  while (my $row = $itr->next) { }
  $itr->reset->first;  # Can't fetch row!

=head1 METHODS

=over

=item $itr->first

get first row data.

=item $itr->next

get next row data.

=item $itr->all

get all row data.

=item $itr->reset

this method reset iterator position number.

=item $itr->count

The number of lines that iterator has are returned. 

=item $itr->no_cache # has been deprecated

=item $itr->cache($mode)

DBIx::Skinny::Itarator is default row data cache.
this method specified that it doesn't cache row data or not. 

if $mode is false, it doesn't cache row data.
$mode is true, it dose cache row data.

=item $itr->position

get iterator current position number.

=item $itr->suppress_objects($mode)

set row object creation mode.

=cut

