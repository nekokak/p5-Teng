package Teng::Schema::Loader;
use strict;
use warnings;
use DBIx::Inspector;
use Teng::Schema;
use Teng::Schema::Table;
use Carp ();
use Class::Load ();

sub load {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $namespace = $args{namespace} or Carp::croak("missing mandatory parameter 'namespace'");

    Class::Load::load_optional_class($namespace) or do {
        # make teng class automatically
        require Teng;
        no strict 'refs'; @{"$namespace\::ISA"} = ('Teng');
    };

    my $teng = $namespace->new(%args, loader => 1);
    my $dbh = $teng->dbh;
    unless ($dbh) {
        Carp::croak("missing mandatory parameter 'dbh' or 'connect_info'");
    }

    my $schema = Teng::Schema->new(namespace => $args{namespace});

    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    for my $table_info ($inspector->tables) {

        my $table_name = $table_info->name;
        my @table_pk   = map { $_->name } $table_info->primary_key;
        my @col_names;
        my %sql_types;
        for my $col ($table_info->columns) {
            push @col_names, $col->name;
            $sql_types{$col->name} = $col->data_type;
        }

        $schema->add_table(
            Teng::Schema::Table->new(
                columns      => \@col_names,
                name         => $table_name,
                primary_keys => \@table_pk,
                sql_types    => \%sql_types,
                inflators    => [],
                deflators    => [],
                row_class    => join '::', $namespace, 'Row', Teng::Schema::camelize($table_name),
            )
        );
    }

    $schema->prepare_from_dbh($dbh);
    $teng->schema($schema);
    return $teng;
}

1;
__END__

=head1 NAME

Teng::Schema::Loader - Dynamic Schema Loader

=head1 SYNOPSIS

    use Teng;
    use Teng::Schema::Loader;

    my $teng = Teng::Schema::Loader->load(
        dbh       => $dbh,
        namespace => 'MyAPP::DB'
    );

=head1 DESCRIPTION

L<Teng::Schema::Loader> loads schema directly from DB.

=head1 CLASS METHODS

=over 4

=item Teng::Schema::Loader->load(%attr)

This is the method to load schema from DB. It returns the instance of the given C<namespace> class which inherits L<Teng>.

The arguments are:

=over 4

=item C<dbh>

Database handle from DBI.

=item namespace

your project name space.

=back

=back

=cut
