package Mock::ErrRow::Row;
use strict;
use warnings;
use base 'DBIx::Skinny::Row';

# syntax error
sub foo {'foo

1;

