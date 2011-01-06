package Mock::ErrRow::Row;
use strict;
use warnings;
use base 'DBIx::Skin::Row';

# syntax error
sub foo {'foo

1;

