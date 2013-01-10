package Teng::Plugin::Count;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/count/;

sub count {
    my ($self, $table, $column, $where, $opt) = @_;

    if (ref $column eq 'HASH') {
        Carp::croak('Do not pass HashRef to second argument. Usage: $db->count($table[, $column[, $where[, $opt]]])');
    }

    $column ||= '*';

    my ($sql, @binds) = $self->sql_builder->select($table, [\"COUNT($column)"], $where, $opt);

    my ($cnt) = $self->dbh->selectrow_array($sql, {}, @binds);
    return $cnt;
}

1;
__END__

=head1 NAME

Teng::Plugin::Count - Count rows in database.

=head1 NAME

    package MyDB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Count');

    package main;
    my $db = MyDB->new(...);
    $db->count('user'); # => The number of rows in 'user' table.
    $db->count('user', '*', {type => 2}); # => SELECT COUNT(*) FROM user WHERE type=2

=head1 DESCRIPTION

This plugin provides shorthand for counting rows in database.

=head1 METHODS

=over 4

=item $db->count($table[, $column[, \%where]]) : Int

I<$table> table name for counting

I<$column> Column name for C<<< COUNT(...) >>>, the default value is '*'.

I<\%where> : HashRef for creating where clause. The format is same as C<< $db->select() >>. This parameter is optional.

I<Return:> The number of rows.

=back

