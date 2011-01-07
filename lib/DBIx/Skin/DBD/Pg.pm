package DBIx::Skin::DBD::Pg;
use strict;
use warnings;
use base 'DBIx::Skin::DBD::Base';

sub quote    { '"' }
sub name_sep { '.' }

1;

