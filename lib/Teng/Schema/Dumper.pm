package Teng::Schema::Dumper;
use strict;
use warnings;
use DBIx::Inspector 0.03;
use Carp ();

sub dump {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh       = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $namespace = $args{namespace} or Carp::croak("missing mandatory parameter 'namespace'");

    my $inspector = DBIx::Inspector->new(dbh => $dbh);

    my $ret = "package ${namespace}::Schema;\n";
    $ret .= "use Teng::Schema::Declare;\n";
    for my $table_info (sort { $a->name cmp $b->name } $inspector->tables) {
        $ret .= "table {\n";
        $ret .= sprintf("    name '%s';\n", $table_info->name);
        $ret .= sprintf("    pk %s;\n", join ',' , map { q{'}.$_->name.q{'} } $table_info->primary_key);
        $ret .= "    columns (\n";
        for my $col ($table_info->columns) {
            if ($col->data_type) {
                $ret .= sprintf("        {name => '%s', type => %s},\n", $col->name, $col->data_type);
            } else {
                $ret .= sprintf("        '%s',\n", $col->name);
            }
        }
        $ret .= "    );\n";

        if (my $rule = $args{inflate}->{$table_info->name}) {
            $ret .= $rule;
        }

        $ret .= "};\n\n";
    }

    $ret .= "1;\n";
    return $ret;
}

1;
__END__

=head1 NAME

Teng::Schema::Dumper - Schema code generator

=head1 SYNOPSIS

    use DBI;
    use Teng::Schema::Dumper;

    my $dbh = DBI->connect(@dsn) or die;
    print Teng::Schema::Dumper->dump(
        dbh       => $dbh,
        namespace => 'Mock::DB',
        inflate   => +{
            user => q|
                use Mock::Inflate::Name;
                inflate 'name' => sub {
                    my ($col_value) = @_;
                    return Mock::Inflate::Name->new(name => $col_value);
                };
                deflate 'name' => sub {
                    my ($col_value) = @_;
                    return ref $col_value ? $col_value->name : $col_value . '_deflate';
                };
                inflate qr/.+oo/ => sub {
                    my ($col_value) = @_;
                    return Mock::Inflate::Name->new(name => $col_value);
                };
                deflate qr/.+oo/ => sub {
                    my ($col_value) = @_;
                    return ref $col_value ? $col_value->name : $col_value . '_deflate';
                };
            |,
        },
    );

=head1 DESCRIPTION

This module generates the Perl code to generate L<Teng::Schema> instance.

You can use it by C<do "my/schema.pl"> or embed it to the package.

=head1 METHODS

=over 4

=item Teng::Schema::Dumper->dump(dbh => $dbh, namespace => $namespace);

This is the method to generate code from DB. It returns the Perl5 code in string.

The arguments are:

=over 4

=item dbh

Database handle from DBI.

=item namespace

your project teng namespace.

=back

=back

