use t::Utils;
use Test::More;

{
    package Mock::Mixin;
    use DBIx::Skin;
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
    use DBIx::Skin::Schema;

    install_table mock_mixin => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

my $db = Mock::Mixin->new(
    +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    }
);

subtest 'mixin Mixin::Foo module' => sub {
    can_ok 'Mock::Mixin', 'foo';
    is +$db->foo, 'foo';
};

done_testing;

