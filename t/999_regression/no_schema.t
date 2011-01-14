use t::Utils;
use Test::More;

{
    package Mock::NoSchema;
    use Teng;
    1;
}

subtest 'do test' => sub {
    eval {
        Mock::NoSchema->schema;
    };
    ok $@;
};

done_testing;
