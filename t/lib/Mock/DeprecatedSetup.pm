package Mock::DeprecatedSetup;
use Teng setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
};

1;
