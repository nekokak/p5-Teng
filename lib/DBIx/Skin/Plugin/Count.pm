package DBIx::Skin::Plugin::Count;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/count/;

sub count {
    my ($self, $table, $column, $where) = @_;

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

