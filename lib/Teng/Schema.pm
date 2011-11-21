package Teng::Schema;
use strict;
use warnings;
use Teng::Row;
use Class::Accessor::Lite
    rw => [ qw(
        tables
        namespace
    ) ]
;

sub new {
    my ($class, %args) = @_;
    bless {
        tables    => {},
        namespace => '',
        %args,
    }, $class;
}

sub set_default_instance {
    my ($class, $instance) = @_;
    no strict 'refs';
    no warnings 'once';
    ${"$class\::DEFAULT_INSTANCE"} = $instance;
}

sub instance {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    ${"$class\::DEFAULT_INSTANCE"};
}

sub add_table {
    my ($self, $table) = @_;
    $self->{tables}->{$table->name} = $table;
}

sub get_table {
    my ($self, $name) = @_;
    return unless $name;
    $self->{tables}->{$name};
}

sub get_row_class {
    my ($self, $table_name) = @_;

    my $table = $self->{tables}->{$table_name};
    return $table->{row_class} if $table;
    return 'Teng::Row';
}

sub camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

sub dump {
    my $self = shift;

    my $namespace = $self->namespace;

    my $ret = "package ${namespace}::Schema;\n";
    $ret .= "use Teng::Schema::Declare;\n";

    for my $table_name (sort { $a->name cmp $b->name } keys %{$self->{tables}}) {
        my $table = $self->get_table($table_name);
        $ret .= "table {\n";
        $ret .= sprintf("    name '%s';\n", $table->name);
        $ret .= sprintf("    pk %s;\n", join ',' , map { q{'}.$_.q{'} } @{$table->primary_keys});
        $ret .= "    columns (\n";
        for my $col (@{$table->columns}) {
            if (my $type = $table->{sql_types}->{$col}) {
                $ret .= sprintf("        {name => '%s', type => %s},\n", $col, $type);
            } else {
                $ret .= sprintf("        '%s',\n", $col);
            }
        }
        $ret .= "    );\n";
        $ret .= "};\n\n";
    }

    $ret .= "1;\n";
    $ret;
}

1;

__END__

=head1 NAME

Teng::Schema - Schema API for Teng

=head1 METHODS

=over 4

=item $schema = Teng::Schema->new

create new Teng::Schema's object.

=item $schema = Teng::Schema->instance

get Teng::Schema's instance object.

=item Teng::Schema->set_default_instance($schema)

set default Schema instance.

=item $schema->add_table($table);

add Teng::Schema::Table's object.

=item my $table = $schema->get_table($table_name);

get Teng::Schema::Table's object.

=item my $row_class = $schema->get_row_class($table_name);

get your table row class or Teng::Row class.

=item $schema->camelize($string)

convert from under_score text to CamelCase one.

=back

=cut

