package Mock::DeprecatedSetup;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
};

1;
