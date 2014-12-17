package xt::Utils::mysql;

use strict;
use warnings;
use Test::More;
use t::Utils;
eval "use Test::mysqld";
plan skip_all => "Test::mysqld required" if $@;

my $mysql = Test::mysqld->new({
    my_cnf => {
        'skip-networking' => '',
    }
})
    or plan skip_all => $Test::mysqld::errstr;

{
    no warnings "redefine";
    sub t::Utils::setup_dbh {
        DBI->connect($mysql->dsn( dbname => "test" ), '','',{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    }
}

1;
