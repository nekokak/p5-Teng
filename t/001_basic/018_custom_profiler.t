use t::Utils;
use Test::More;

{
    package Mock::CustomProfiler::Profiler;
    use strict;
    use warnings;
    use base qw(DBIx::Skinny::Profiler);

    package Mock::CustomProfiler;
    use t::Utils;
    use DBIx::Skinny
        profiler => Mock::CustomProfiler::Profiler->new,
        connect_info => +{
            dsn => 'dbi:SQLite:',
            username => '',
            password => '',
        }
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
    use DBIx::Skinny::Schema;

    install_table mock_custom_profiler => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
}

isa_ok(Mock::CustomProfiler->profiler, "Mock::CustomProfiler::Profiler", "it should be able to replace profiler class");
Mock::CustomProfiler->_attributes->{profile} = 1;
Mock::CustomProfiler->setup_test_db;
Mock::CustomProfiler->search('mock_custom_profiler', { });
ok(Mock::CustomProfiler->profiler->query_log, 'query log recorded');

done_testing();
