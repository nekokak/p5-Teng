package Mock::DeprecatedSetup;
use DBIx::Skin setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
};

1;
