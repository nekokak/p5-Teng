package Teng::Plugin::Pager::Count;

use strict;
use warnings;
use Data::Page;
use Teng::Plugin::Pager ();
use Class::Load ();

our @EXPORT = qw/search_with_pager/;

my %alternative_pager;

sub init {
    my ($pkg, $class, $opt) = @_;
    if ($opt->{alternative_pager}) {
        $alternative_pager{ref $class ? ref $class : $class} = $opt->{alternative_pager};
    }
}

sub search_with_pager {
    my ($self, $table_name, $where, $opt) = @_;

    if (exists $opt->{group_by}) {
        if (my $alternative_class = $alternative_pager{ref $self}) {
            Class::Load::load_class('Teng::Plugin::' . $alternative_class);
            my $method = 'Teng::Plugin::' . $alternative_class . '::' . 'search_with_pager';
            return $self->$method($table_name, $where, $opt);
        } else {
            Carp::croak("Cannot use group_by option with Teng::Plugin::Pager::Count::search_with_pager or set alternative_pager when load_plugin");
        }
    }

    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};

    my ($count_sql, @count_binds) = $self->sql_builder->select(
        $table_name,
        [\'COUNT(*)'],
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
    my $count_sth = $self->dbh->prepare($count_sql) or Carp::croak $self->dbh->errstr;
    $count_sth->execute(@count_binds) or Carp::croak $self->dbh->errstr;
    my $total_entries = $count_sth->fetchrow_arrayref->[0];

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
__END__

=for test_synopsis
my ($c, $dbh);

=head1 NAME

Teng::Plugin::Pager::Count - Paginate with COUNT(*)

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Pager::Count');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_with_pager('user' => {type => 3}, {page => $page, rows => 5});

If you want to use alternate pager when you use group_by:

    __PACKAGE__->load_plugin('Pager::Count', {alternative_pager => 'Pager'});
    __PACKAGE__->load_plugin('Pager::Count', {alternative_pager => 'Pager::MySQLFoundRows'});

=head1 DESCRIPTION

This is a helper class for pagination. This helper only supports B<MySQL>.
Since this plugin uses COUNT(*) for calculate total entries.

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

