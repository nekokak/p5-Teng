use strict;
use Test::More;
use t::Utils;

use_ok "Mock::ExplicitSchema";

is Mock::ExplicitSchema->schema, "Mock::ExplicitSchemaSchema";

done_testing;