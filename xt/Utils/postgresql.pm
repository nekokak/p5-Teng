package xt::Utils::postgresql;

use strict;
use warnings;
use Test::postgresql;
use Test::More;
use t::Utils;

my $pgsql = Test::postgresql->new
    or plan skip_all => $Test::postgresql::errstr;

{
    no warnings "redefine";
    sub t::Utils::setup_dbh {
        my $dbh = DBI->connect($pgsql->dsn);
        $dbh->{"Warn"} = 0;
        $dbh;
    }
}

1;
