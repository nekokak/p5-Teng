use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Test::More 0.96;

BEGIN { use_ok( 'Mock::Basic' ); }

isa_ok 'Mock::Basic', 'Teng';

use DBD::SQLite;
diag('DBD::SQLite versin is '.$DBD::SQLite::VERSION);

done_testing;
