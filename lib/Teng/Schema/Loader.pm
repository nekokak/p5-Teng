package Teng::Schema::Loader;
use strict;
use warnings;
use DBIx::Inspector;
use Teng::Schema;
use Teng::Schema::Table;
use Carp ();

sub load {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $namespace = $args{namespace} or Carp::croak("missing mandatory parameter 'namespace'");

    my $schema = Teng::Schema->new();

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
    return $schema;
}

1;
__END__

=head1 NAME

Teng::Schema::Loader - Dynamic Schema Loader

=head1 SYNOPSIS

    use Teng;
    use Teng::Schema::Loader;

    my $schema = Teng::Schema::Loader->load(
        dbh       => $dbh,
        namespace => 'MyAPP::DB'
    );
    my $teng = Teng->new(
        dbh    => $dbh,
        schema => $schema
    );

=head1 DESCRIPTION

L<Teng::Schema::Loader> loads schema directly from DB.

=head1 CLASS METHODS

=over 4

=item Teng::Schema::Loader->load(%attr)

This is the method to load schema from DB. It returns instance of L<Teng::Scehema>.

The arguments are:

=item dbh

Database handle from DBI.

=item namespace

your project name space.

=back

=cut
