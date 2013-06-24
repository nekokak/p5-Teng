package Teng::Plugin::SQLPager;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/search_by_sql_with_pager/;

use Data::Page::NoTotalEntries;

sub search_by_sql_with_pager {
    my ($self, $sql, $binds, $opt, $table_name) = @_;
    $table_name ||= $self->_guess_table_name( $sql );

    my $page = 0+$opt->{page};
    my $entries_per_page = 0+$opt->{rows};
    my $offset = ( $page - 1 ) * $entries_per_page;

    $sql .= " LIMIT @{[ $entries_per_page + 1 ]} OFFSET $offset";

    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@$binds) or Carp::croak $self->dbh->errstr;

    my $itr = Teng::Iterator->new(
        teng             => $self,
        sth              => $sth,
        sql              => $sql,
        row_class        => $self->schema->get_row_class($table_name),
        table_name       => $table_name,
        suppress_object_creation => $self->suppress_row_objects,
    );
    my $rows = [$itr->all];
    my $has_next = 0;
    if (@$rows == $entries_per_page + 1) {
        pop @$rows;
        $has_next++;
    }

    my $pager = Data::Page::NoTotalEntries->new(
        entries_per_page => $entries_per_page,
        current_page     => $page,
        has_next         => $has_next,
    );

    return ($rows, $pager);
}


1;
__END__

=head1 NAME

Teng::Plugin::SQLPager - Paginate with SQL

=head1 SYNOPSIS

    package My::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin(qw/SQLPager/);

    # in your application
    $db->search_by_sql_with_pager(
        q{SELECT * FROM member ORDER BY id DESC},
        [],
        {page => 1, rows => 20}
    );

=head1 DESCRIPTION

This module searches database by SQL with paginate.

search_by_sql_with_pager method adds LIMIT clause automatically.

=head1 ARGUMENTS FOR search_by_sql_with_pager

You can pass arguments as following.

    $db->search_by_sql_with_pager($sql, $binds, $opt[, $table_name]);

=over 4

=item $sql: Str

This is a SQL statement in string.

=item $binds: ArrayRef[Str]

This is a bind values in arrayref.

=item $opt: HashRef

Options for search_by_sql_with_pager. Important options are 'page' and 'rows'.

B<page> is a current page number. B<rows> is a entries per page.

=item $table_name: Str

You can pass a table name.

This argument is optional. If you don't pass a table name, Teng guess table name automatically.

=back

=head1 LIMITATIONS

This module does not work with Oracle since Oracle does not support limit clause.

