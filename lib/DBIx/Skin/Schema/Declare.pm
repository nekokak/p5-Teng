package DBIx::Skin::Schema::Declare;
use strict;
use DBIx::Skin::Schema;
use DBIx::Skin::Schema::Table;
use base qw(Exporter);

our @EXPORT = qw(
    schema
    name
    table
    pk
    columns
);

sub name($);
sub table(&);
sub pk(@);
sub columns(@);
sub schema (&) {
    my $code = shift;

    my (
        %tables,
        $schema_class,
        $schema_options,
    );

    $schema_class = caller();

    local *name       = sub ($) { $schema_class = shift };
    local *options  = sub ($) { $schema_options = shift };
    local *table    = sub (&) {
        my $code = shift;
        my (
            $table_name,
            @table_pk,
            @table_columns,
        );
        local *name    = sub ($) { $table_name = shift };
        local *pk      = sub (@) { @table_pk = @_ };
        local *columns = sub (@) { @table_columns = @_ };
        $code->();

        $tables{$table_name} = DBIx::Skin::Schema::Table->new(
            name => $table_name,
            primary_keys => \@table_pk,
            columns => \@table_columns,
        ); 
    };

    $code->();

    if (! $schema_class->isa( 'DBIx::Skin::Schema' ) ) {
        no strict 'refs';
        push @{ "$schema_class\::ISA" }, 'DBIx::Skin::Schema';
    }
    my $schema = $schema_class->new(
        tables => \%tables,
    );
    $schema_class->set_default_instance( $schema );
    
    return $schema;
}

1;
