package Teng::Plugin::Pager;
use strict;
use warnings;
use utf8;
use Carp ();
use DBI;
use Teng::Iterator;
use Data::Page::NoTotalEntries;

our @EXPORT = qw/search_with_pager/;

sub search_with_pager {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};
    for (qw/page rows/) {
        Carp::croak("missing mandatory parameter: $_") unless exists $opt->{$_};
    }

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
            limit => $rows + 1,
            offset => $rows*($page-1),
        }
    );

    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;

    my $ret = [ Teng::Iterator->new(
        teng             => $self,
        sth              => $sth,
        sql              => $sql,
        row_class        => $self->schema->get_row_class($table_name),
        table            => $table,
        table_name       => $table_name,
        suppress_object_creation => $self->suppress_row_objects,
    )->all];

    my $has_next = ( $rows + 1 == scalar(@$ret) ) ? 1 : 0;
    if ($has_next) { pop @$ret }

    my $pager = Data::Page::NoTotalEntries->new(
        entries_per_page     => $rows,
        current_page         => $page,
        has_next             => $has_next,
        entries_on_this_page => scalar(@$ret),
    );

    return ($ret, $pager);
}

1;
__END__

=for test_synopsis
my ($dbh, $c);

=head1 NAME

Teng::Plugin::Pager - Pager

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Pager');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_with_pager('user' => {type => 3}, {page => $page, rows => 5});

=head1 DESCRIPTION

This is a helper for pagination.

This pager fetches "entries_per_page + 1" rows. And detect "this page has a next page or not".

=head1 METHODS

=over 4

=item my (\@rows, $pager) = $db->search_with_pager($table_name, \%where, \%opts)

Select from database with pagination.

The arguments are mostly same as C<$db->search()>. But two additional options are available.

=over 4

=item $opts->{page}

Current page number.

=item $opts->{rows}

The number of entries per page.

=back

This method returns ArrayRef[Teng::Row] and instance of L<Data::Page::NoTotalEntries>.

=back
