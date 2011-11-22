package Teng::Plugin::SingleBySQL;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/single_by_sql/;


sub single_by_sql {
    my ($self, $sql, $bind, $table_name) = @_;

    $table_name ||= $self->_guess_table_name( $sql );
    my $table = $self->{schema}->get_table( $table_name );
    Carp::croak("No such table $table_name") unless $table;

    my $sth = $self->_execute($sql, $bind);
    my $row = $sth->fetchrow_hashref('NAME_lc');

    return unless $row;
    return $row if $self->{suppress_row_objects};

    $table->{row_class}->new(
        {
            sql        => $sql,
            row_data   => $row,
            teng       => $self,
            table      => $table,
            table_name => $table_name,
        }
    );
}

1;
__END__

=head1 NAME

Teng::Plugin::SingleBySQL - single by sql

=head1 PROVIDED METHODS

=over 4

=item $row = $teng->single_by_sqle($sql, [\%bind_values, [$table_name]])

get one record from your SQL.

    my $row = $teng->single_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user');

=back

