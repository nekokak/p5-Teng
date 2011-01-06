use t::Utils;
use Test::More;

{
    package Mock::NoCheckSchema;
    use DBIx::Skinny connect_info => +{
        check_schema => 0,
    };
}

local $@;
eval {
    my $rs = Mock::NoCheckSchema->search('foo_bar', {id => 1});
};

unlike($@, qr/is it realy loaded/);

done_testing();
