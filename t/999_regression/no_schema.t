use t::Utils;
use Test::More;

{
    package Mock::NoSchema;
    use DBIx::Skinny;
    1;
}

subtest 'do test' => sub {
    eval {
        Mock::NoSchema->schema;
    };
    ok $@;
};

done_testing;
