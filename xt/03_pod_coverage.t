use strict;
use warnings;
use utf8;
use Test::More;

use Test::Requires {'Test::Pod::Coverage' => '1.00'};
all_pod_coverage_ok({also_private => [
    qr/(?:
        prepare_from_dbh          |
        in_transaction_check      |
        generate_column_accessor
    )/x
]});
