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
    trigger
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
        %schema_triggers,
    );

    $schema_class = caller();

    no warnings 'redefine';
    local *name    = sub ($) { $schema_class = shift };
    local *trigger = sub ($&) {
        my $list = $schema_triggers{$_[0]};
        if (! $list) {
            $schema_triggers{$_[0]} = $list = [];
        }
        push @$list, $_[1]
    };
    local *table   = sub (&) {
        my $code = shift;
        my (
            $table_name,
            @table_pk,
            @table_columns,
            %table_triggers,
        );
        local *name    = sub ($) { $table_name = shift };
        local *pk      = sub (@) { @table_pk = @_ };
        local *columns = sub (@) { @table_columns = @_ };
        local *trigger = sub ($&) {
            my $list = $table_triggers{$_[0]};
            if (! $list) {
                $table_triggers{$_[0]} = $list = [];
            }
            push @$list, $_[1]
        };
        $code->();

        $tables{$table_name} = DBIx::Skin::Schema::Table->new(
            columns      => \@table_columns,
            name         => $table_name,
            primary_keys => \@table_pk,
            triggers     => \%table_triggers,
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
