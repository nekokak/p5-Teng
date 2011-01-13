use strict;
use Test::More;
use DBIx::Skin::Schema::Declare;

subtest 'edge cases' => sub {
    my $klass = "DBIx::Skin::TestFor::Declare002Schema";
    my $schema = schema {
        table {
            name 'foo';
        };
    } $klass;

    ok $schema;
    isa_ok $schema, $klass;

    ok ! $schema->get_table( "bar" ), "non existent table should return undef";
    ok ! $schema->get_table(), "no name given should return undef";
};

done_testing;