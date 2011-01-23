package Teng::Plugin::Pager;
use strict;
use warnings;
use utf8;
use Carp ();
use DBI;
use Teng::Iterator;

our @EXPORT = qw/search_with_pager/;

sub search_with_pager {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};
    for (qw/page rows/) {
        Carp::croak("missing mandatory parameter: $_") unless exists $opt->{$_};
    }

    my ($sql, @binds) = $self->sql_builder->select(
        $table_name,
        $table->columns,
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
        table_name       => $table_name,
        suppress_object_creation => $self->suppress_row_objects,
    )->all];

    my $has_next = ( $rows + 1 == scalar(@$ret) ) ? 1 : 0;
    if ($has_next) { pop @$ret }

    my $pager = Teng::Plugin::Pager::Page->new(
        entries_per_page     => $rows,
        current_page         => $page,
        has_next             => $has_next,
        entries_on_this_page => scalar(@$ret),
    );

    return ($ret, $pager);
}

package Teng::Plugin::Pager::Page;
use Class::Accessor::Lite (
    ro => [qw/entries_per_page current_page has_next entries_on_this_page/],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next_page {
    my $self = shift;
    $self->has_next ? $self->current_page + 1 : undef;
}

sub previous_page { shift->prev_page(@_) }
sub prev_page {
    my $self = shift;
    $self->current_page > 1 ? $self->current_page - 1 : undef;
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

This method returns ArrayRef[Teng::Row] and instance of L<Teng::Plugin::Pager::Page>.

=back

=head1 Teng::Plugin::Pager::Page

B<search_with_pager> method returns the instance of Teng::Plugin::Pager::Page. It gives paging information.

=head2 METHODS

=over 4

=item $pager->entries_per_page()

The number of entries per page('rows'. you provided).

=item $pager->current_page()

Returns: fetched page number.

=item $pager->has_next()

The page has next page or not in boolean value.

=item $pager->entries_on_this_page()

How many entries on this page?

=item $pager->next_page()

The page number of next page.

=item $pager->previous_page()

The page number of previous page.

=item $pager->prev_page()

Alias for C<<< $pager->previous_page() >>>.

=back
