use strict;
use Test::More;
use t::Utils;

use_ok "Mock::ExplicitSchema";

my $dbh = t::Utils->setup_dbh;
my $db = Mock::ExplicitSchema->new({ dbh => $dbh });

is $db->schema, "Mock::ExplicitSchemaSchema";

done_testing;
