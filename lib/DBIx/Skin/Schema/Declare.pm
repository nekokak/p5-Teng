package DBIx::Skin::Schema::Declare;
use strict;
use warnings;
use DBIx::Skin::Schema;
use DBIx::Skin::Schema::Table;
use Scalar::Util ();
use base qw(Exporter);

our @EXPORT = qw(
    schema
    name
    table
    pk
    columns
    row_class
    inflate
    deflate
);
our $CURRENT_SCHEMA_CLASS;

sub schema (&;$) { 
    my ($code, $schema_class) = @_;
    local $CURRENT_SCHEMA_CLASS = $schema_class;
    $code->();
    _current_schema();
}

sub _current_schema {
    
    my $class = $CURRENT_SCHEMA_CLASS || __PACKAGE__;
    my $schema_class;

    my $i = 1;
    while ( $schema_class = caller($i++) ) {
        if ( ! $schema_class->isa( $class ) ) {
            last;
        }
    }

    if (! $schema_class) {
        Carp::confess( "PANIC: cannot find a package name that is not ISA $class" );
    }

    no warnings 'once';
    if (! $schema_class->isa( 'DBIx::Skin::Schema' ) ) {
        no strict 'refs';
        push @{ "$schema_class\::ISA" }, 'DBIx::Skin::Schema';
        my $schema = $schema_class->new();
        $schema_class->set_default_instance( $schema );
    }

    $schema_class->instance();
}

sub pk(@);
sub columns(@);
sub name ($);
sub row_class ($);
sub inflate_rule ($@);
sub table(&) {
    my $code = shift;
    my $current = _current_schema();

    my (
        $table_name,
        @table_pk,
        @table_columns,
        %inflate,
        %deflate,
        $row_class,
    );
    no warnings 'redefine';
    
    my $schema_class = Scalar::Util::blessed($current);
    no strict 'refs';
    no warnings 'once';
    local *{"$schema_class\::name"}      = sub ($) { $table_name = shift };
    local *{"$schema_class\::pk"}        = sub (@) { @table_pk = @_ };
    local *{"$schema_class\::columns"}   = sub (@) { @table_columns = @_ };
    local *{"$schema_class\::row_class"} = sub (@) { $row_class = shift };
    local *{"$schema_class\::inflate"} = sub ($&) {
        $inflate{ $_[0] } = $_[1];
    };
    local *{"$schema_class\::deflate"} = sub ($&) {
        $deflate{ $_[0] } = $_[1];
    };

    $code->();

    my @col_names;
    my %sql_types;
    while ( @table_columns ) {
        my $col_name = shift @table_columns;
        if (ref $col_name) {
            my $sql_type = $col_name;
            $col_name = $col_name->{ name };
            $sql_types{ $col_name } = $sql_type;
        }
        push @col_names, $col_name;
    }

    $current->add_table(
        DBIx::Skin::Schema::Table->new(
            columns      => \@col_names,
            name         => $table_name,
            primary_keys => \@table_pk,
            sql_types    => \%sql_types,
            inflators    => \%inflate,
            deflators    => \%deflate,
            row_class    => $row_class,
        )
    ); 
}

1;

__END__

=head1 NAME

DBIx::Skin::Schema::Declare - DSL For Declaring DBIx::Skin Schema

=head1 NORMAL USE

    package MyDB::Schema;
    use strict;
    use DBIx::Skin::Schema::Declare;

    table {
        name "your_table_name";
        pk "primary_key";
        columns qw( col1 col2 col3 );
    };

=head1 INLINE DECLARATION

    use DBIx::Skin::Schema::Declare;
    my $schema = schema {
        table {
            name "your_table_name";
            columns qw( col1 col2 col3 );
        };
    } "MyDB::Schema";

=cut
