use strict;
use Test::More;
BEGIN {
    use_ok "DBIx::Skin::Schema::Declare";
}

subtest 'basic declare' => sub {
    my $schema = schema {
        name 'DBIx::Skin::TestSchema';
        table {
            pk 'id';
            name "foo_table";
            columns qw( foo bar baz );
        };
    };

    ok $schema, "schema is defined";
    isa_ok $schema, "DBIx::Skin::Schema";

    my $tables = $schema->tables;
    ok $tables, "tables are defined";

    my $table = $schema->get_table( "foo_table" );
    isa_ok $table, "DBIx::Skin::Schema::Table";
    is $table->name, "foo_table", "table name matches";

    my $pk = $table->primary_keys;
    my $columns = $table->columns;
    is_deeply $pk, [ 'id' ], "table id matches";
    is_deeply $columns, [ qw(foo bar baz) ], "table columns matches";
};

done_testing;