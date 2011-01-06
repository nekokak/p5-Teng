use t::Utils;
use Test::More;

use DBIx::Skinny::Profiler;

my $profiler = DBIx::Skinny::Profiler->new;

subtest 'record query' => sub {
    $profiler->record_query(q{SELECT * FROM user});
    is_deeply $profiler->query_log, [
        q{SELECT * FROM user},
    ];
};

subtest 'record query /_normalize' => sub {
    $profiler->record_query(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            name like "%neko%"
    });
    is_deeply $profiler->query_log, [
        q{SELECT * FROM user},
        q{SELECT id, name FROM user WHERE name like "%neko%"},
    ];
};

subtest 'reset' => sub {
    $profiler->reset;
    is_deeply $profiler->query_log, [];
};

subtest 'recorde bind values' => sub {
    $profiler->record_query(q{
        SELECT id FROM user WHERE id = ?
    },[1]);
    is_deeply $profiler->query_log, [
        q{SELECT id FROM user WHERE id = ? :binds 1},
    ];

    $profiler->record_query(q{
        SELECT id FROM user WHERE (id = ? OR id = ?)
    },[1, 2]);

    $profiler->record_query(q{
        INSERT INTO user (name) VALUES (?)
    },[undef]);

    is_deeply $profiler->query_log, [
        q{SELECT id FROM user WHERE id = ? :binds 1},
        q{SELECT id FROM user WHERE (id = ? OR id = ?) :binds 1, 2},
        q{INSERT INTO user (name) VALUES (?) :binds undef},
    ];
};

done_testing;

