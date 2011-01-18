package Teng::Iterator;
use strict;
use warnings;
use Carp ();
use Class::Accessor::Lite (
    rw => [qw/suppress_objects/],
);

sub new {
    my ($class, %args) = @_;

    return bless \%args, $class;
}

sub next {
    my $self = shift;

    my $row;
    if ($self->{sth}) {
        $row = $self->{sth}->fetchrow_hashref('NAME_lc');
        unless ( $row ) {
            $self->{sth}->finish;
            $self->{sth} = undef;
            return;
        }
    } else {
        return;
    }

    if ($self->suppress_objects) {
        return $row;
    } else {
        return $self->{row_class}->new(
            {
                sql        => $self->{sql},
                row_data   => $row,
                teng       => $self->{teng},
                table_name => $self->{table_name},
            }
        );
    }
}

sub all {
    my $self = shift;
    my @result;
    while ( my $row = $self->next ) {
        push @result, $row;
    }
    return wantarray ? @result : \@result;
}

1;

__END__
=head1 NAME

Teng::Iterator

=head1 DESCRIPTION

Teng iteration class.

=head1 SYNOPSIS

  my $itr = Your::Model->search('user',{});
  
  my @rows = $itr->all; # get all rows

  # do iteration
  while (my $row = $itr->next) {
    ...
  }

=head1 METHODS

=over

=item $itr = Teng::Iterator->new

create new Teng::Iterator's object.

=item $itr->next

get next row data.

=item $itr->all

get all row data in array.

=item $itr->suppress_objects($mode)

set row object creation mode.

=cut

