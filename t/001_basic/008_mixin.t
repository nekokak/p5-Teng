use t::Utils;
use Test::More;

{
    package Mock::Mixin;
    use base qw( DBIx::Skin );
    use DBIx::Skin::Mixin modules => ['+Mixin::Foo'];

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_mixin (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::Mixin::Schema;
    use utf8;
    use DBIx::Skin::Schema::Declare;

    table {
        name 'mock_mixin';
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

my $db = Mock::Mixin->new(
    connect_info => [ 'dbi:SQLite:' ]
);

subtest 'mixin Mixin::Foo module' => sub {
    can_ok 'Mock::Mixin', 'foo';
    is +$db->foo, 'foo';
};

done_testing;

