package Teng::Iterator;
use strict;
use warnings;
use Carp ();
use Class::Accessor::Lite (
    rw => [qw/suppress_object_creation/],
);

sub new {
    my ($class, %args) = @_;

    return bless \%args, $class;
}

sub next {
    my $self = shift;

    my $row;
    if ($self->{sth}) {
        $row = $self->{sth}->fetchrow_hashref;
        $self->{select_columns} ||= $self->{sth}->{$self->{teng}->{fields_case}};
        unless ( $row ) {
            $self->{sth}->finish;
            $self->{sth} = undef;
            return;
        }
    } else {
        return;
    }

    if ($self->{suppress_object_creation}) {
        return $row;
    } else {
        return $self->{row_class}->new(
            {
                sql            => $self->{sql},
                row_data       => $row,
                teng           => $self->{teng},
                table          => $self->{table},
                table_name     => $self->{table_name},
                select_columns => $self->{select_columns},
            }
        );
    }
}

sub all {
    my $self = shift;

    my $result = [];

    if ($self->{sth}) {
        $self->{select_columns} ||= $self->{sth}->{$self->{teng}->{fields_case}};
        $result = $self->{sth}->fetchall_arrayref(+{});
        $self->{sth}->finish;
        $self->{sth} = undef;

        if (!$self->{suppress_object_creation}) {
            $result = [map {
                $self->{row_class}->new(
                    {
                        sql            => $self->{sql},
                        row_data       => $_,
                        teng           => $self->{teng},
                        table          => $self->{table},
                        table_name     => $self->{table_name},
                        select_columns => $self->{select_columns},
                    }
                )
            } @$result];
        }
    }

    return wantarray ? @$result : $result;
}

1;

__END__
=head1 NAME

Teng::Iterator - Iterator for Teng

=head1 DESCRIPTION

This is an iterator class for L<Teng>.

=head1 SYNOPSIS

  my $itr = Your::Model->search('user',{});
  
  my @rows = $itr->all; # get all rows

  # do iteration
  while (my $row = $itr->next) {
    ...
  }

=head1 METHODS

=over

=item $itr = Teng::Iterator->new()

Create new Teng::Iterator's object. You may not call this method directly.

=item my $row = $itr->next();

Get next row data.

=item my @ary = $itr->all;

Get all row data in array.

=item $itr->suppress_object_creation($bool)

Set row object creation mode.

=back

=cut

