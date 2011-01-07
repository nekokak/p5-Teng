use t::Utils;
use Test::More;

{
    package Mock::CustomProfiler::Profiler;
    use strict;
    use warnings;
    use base qw(DBIx::Skin::Profiler);

    package Mock::CustomProfiler;
    use t::Utils;
    use DBIx::Skin
        profiler => Mock::CustomProfiler::Profiler->new,
    ;

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_custom_profiler (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::CustomProfiler::Schema;
    use utf8;
    use DBIx::Skin::Schema;

    install_table mock_custom_profiler => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

my $db = Mock::CustomProfiler->new({
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
});
isa_ok($db->profiler, "Mock::CustomProfiler::Profiler", "it should be able to replace profiler class");
$db->{profile} = 1;
$db->setup_test_db;
$db->search('mock_custom_profiler', { });
ok($db->profiler->query_log, 'query log recorded');

done_testing();
