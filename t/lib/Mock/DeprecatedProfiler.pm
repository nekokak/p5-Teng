package Mock::DeprecatedSetup;
use DBIx::Skinny::Profiler;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
    profiler => DBIx::Skinny::Profiler->new,
};

1;
