package Mock::DeprecatedSetup;
use DBIx::Skin::Profiler;
use DBIx::Skin connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
    profiler => DBIx::Skin::Profiler->new,
};

1;
