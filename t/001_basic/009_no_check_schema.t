use t::Utils;
use Test::More;

TODO: {
    todo_skip "XXX nekokak", 1;

{
    package Mock::NoCheckSchema;
    use DBIx::Skin;
}

my $db = Mock::NoCheckSchema->new(
    +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
        check_schema => 0,
    }
);

local $@;
eval {
    my $rs = $db->search('foo_bar', {id => 1});
};

unlike($@, qr/is it realy loaded/);
};

done_testing();
