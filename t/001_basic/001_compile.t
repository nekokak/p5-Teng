use t::Utils;
use Test::More;

BEGIN { use_ok( 'Mock::Basic' ); }

isa_ok 'Mock::Basic', 'DBIx::Skinny';

use DBD::SQLite;
diag('DBD::SQLite versin is '.$DBD::SQLite::VERSION);

done_testing;
