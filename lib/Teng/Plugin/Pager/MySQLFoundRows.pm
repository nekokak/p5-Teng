package Teng::Plugin::Pager::MySQLFoundRows;
use strict;
use warnings;
use utf8;
use Data::Page;
use Teng::Iterator;
use Carp ();

our @EXPORT = qw/search_with_pager/;

sub search_with_pager {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};

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
            prefix => 'SELECT SQL_CALC_FOUND_ROWS ',
        }
    );
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;
    my $total_entries = $self->dbh->selectrow_array(q{SELECT FOUND_ROWS()});

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
__END__

=for test_synopsis
my ($c, $dbh);

=head1 NAME

Teng::Plugin::Pager::MySQLFoundRows - Paginate with SQL_CALC_FOUND_ROWS

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Pager::MySQLFoundRows');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_with_pager('user' => {type => 3}, {page => $page, rows => 5});

=head1 DESCRIPTION

This is a helper class for pagination. This helper only supports B<MySQL>.
Since this plugin uses SQL_CALC_FOUND_ROWS for calculate total entries.

=head1 METHODS

=over 4

=item my (\@rows, $pager) = $db->search_with_pager($table, \%where, \%opts);

Select from database with pagination.

The arguments are mostly same as C<$db->search()>. But two additional options are available.

=over 4

=item $opts->{page}

Current page number.

=item $opts->{rows}

The number of entries per page.

=back

This method returns ArrayRef[Teng::Row] and instance of L<Teng::Plugin::Pager::Page>.

=back

=head1 AUTHOR

Tokuhiro Matsuno

