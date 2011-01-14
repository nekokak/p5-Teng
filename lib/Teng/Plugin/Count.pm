package Teng::Plugin::Count;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/count/;

sub count {
    my ($self, $table, $column, $where) = @_;
    $column ||= '*';

    my $select = $self->sql_builder->new_select();

    $select->add_select(\"COUNT($column)");
    $select->add_from($table);
    $select->add_where($_ => $where->{$_}) for keys %{ $where || {} };

    my $sql = $select->as_sql();
    my @bind = $select->bind();

    my ($cnt) = $self->dbh->selectrow_array($sql, {}, @bind);
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

