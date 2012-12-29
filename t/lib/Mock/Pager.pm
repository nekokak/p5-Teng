package Mock::Pager;

use strict;
use warnings;
use Data::Page;

our @EXPORT = qw/search_with_pager/;
our %cache;

sub search_with_pager {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};

    my ($count_sql, @count_binds) = $self->sql_builder->select(
        $table_name,
        [\'count(*)'],
        $where,
        $opt,
    );

    my $columns = $opt->{'+columns'}
        ? [@{$table->{columns}}, @{$opt->{'+columns'}}]
        : ($opt->{columns} || $table->{columns})
    ;

    my ($sql, @binds) = $self->sql_builder->select(
        $table_name,
        $columns,
        $where,
        +{
            %$opt,
            limit  => $rows,
            offset => $rows*($page-1),
        }
    );
    my $total_entries = $cache{$count_sql};
    if (not $total_entries) {
        my $count_sth = $self->dbh->prepare($count_sql) or Carp::croak $self->dbh->errstr;

        $count_sth->execute(@count_binds) or Carp::croak $self->dbh->errstr;
        $cache{$count_sql} = $total_entries = $count_sth->fetchrow_arrayref->[0];
    }

    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;

    my $itr = Teng::Iterator->new(
        teng             => $self,
        sth              => $sth,
        sql              => $sql,
        row_class        => $self->schema->get_row_class($table_name),
        table            => $table,
        table_name       => $table_name,
        suppress_object_creation => $self->suppress_row_objects,
    );

    my $pager = Data::Page->new();
    $pager->entries_per_page($rows);
    $pager->current_page($page);
    $pager->total_entries($total_entries);

    return ([$itr->all], $pager);
}

1;
