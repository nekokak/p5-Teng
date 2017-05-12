package Teng::Iterator;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw/looks_like_number/;
use Class::Accessor::Lite (
    rw => [qw/suppress_object_creation apply_sql_types guess_sql_types/],
);
use DBI qw(:sql_types);

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
        $self->_apply_sql_types($row) if $self->{apply_sql_types};
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

sub _apply_sql_types {
    my ($self, $row) = @_;

    foreach my $column (keys %$row) {
        my $type = $self->{table}->{sql_types}->{$column};
        if (defined $type) {
            if (   $type == SQL_BIGINT
                or $type == SQL_BIT
                or $type == SQL_TINYINT
                or $type == SQL_NUMERIC
                or $type == SQL_INTEGER
                or $type == SQL_SMALLINT
                or $type == SQL_DECIMAL
                or $type == SQL_FLOAT
                or $type == SQL_REAL
                or $type == SQL_DOUBLE
               ) {
                $row->{$column} += 0;
            } elsif ($type == SQL_BOOLEAN) {
                if ($self->{teng}->{boolean_value}) {
                    if ($row->{$column}) {
                        $row->{$column} = $self->{teng}->{boolean_value}->{true};
                    } else {
                        $row->{$column} = $self->{teng}->{boolean_value}->{false};
                    }
                } else {
                    $row->{$column} += 0;
                }
            } else {
                $row->{$column} .= '';
            }
        } elsif ($self->{guess_sql_types}) {
            if (looks_like_number($row->{$column})) {
                $row->{$column} += 0;
            } else {
                $row->{$column} .= '';
            }
        }
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

=item $itr->apply_sql_types($bool)

Set column type application mode.

If column has SQL type and it is numeric, regard it as number and add 0 to the value.
If column has SQL type and it isn't numeric, regard it as string and add '' to the value.
If column doesn't have SQL type, the value won't be changed.

=item $itr->guess_sql_types($bool)

If this is true, this implies apply_sql_types also true.
If column has no SQL type, it guesses SQL type with its value.
When column value likes numeric, regard it as number and add 0 to the value.
If not, regard it as string and add '' to the value.

=back

=cut

