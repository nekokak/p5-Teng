package xt::Utils::postgresql;

use strict;
use warnings;
use Test::More;
use t::Utils;
use Test::Requires {
    'DBD::Pg' => '0',
    'Test::PostgreSQL' => '1.00'
};

my $pgsql = Test::PostgreSQL->new
    or plan skip_all => $Test::PostgreSQL::errstr;

{
    no warnings "redefine";
    sub t::Utils::setup_dbh {
        my $dbh = DBI->connect($pgsql->dsn);
        $dbh->{"Warn"} = 0;
        $dbh;
    }
}

1;
