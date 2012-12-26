package Teng::Plugin::Lookup;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/lookup/;

sub lookup {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->{schema}->get_table( $table_name );
    Carp::croak("No such table $table_name") unless $table;

    my (@keys, $values);
    if ( ref $where eq 'ARRAY' ) {
        my @w = @$where;
        while (my ($key, $val) = splice @w, 0, 2) {
            push @keys, $key;
            push @$values, $val;
        }
    }
    else {
        @keys = sort keys %$where;
        $values = [@$where{@keys}];
    }

    my $dbh = $self->dbh;
    my $columns = $self->_get_select_columns($table, $opt);
    my $cond = join ' AND ', map {$dbh->quote_identifier($_) . ' = ?'} @keys;
    my $sql = sprintf('SELECT %s FROM %s WHERE %s %s',
               join(',', map { ref $_ ? $$_ : $_ } @{$columns}),
               $table_name,
               $cond,
               $opt->{for_update} ? 'FOR UPDATE' : '',
           );

    my $sth = $self->execute($sql, $values);
    my $row = $sth->fetchrow_hashref($self->{fields_case});

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

Teng::Plugin::Lookup - lookup single row.

=head1 NAME

    package MyDB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Lookup');

    package main;
    my $db = MyDB->new(...);
    $db->lookup('user' => +{id => 1}); # => get single row

=head1 DESCRIPTION

This plugin provides fast lookup row .

=head1 METHODS

=over 4

=item $row = $db->lookup($table_name, \%search_condition, [\%attr]);

lookup single row records.

Teng#single is heavy.

=back

