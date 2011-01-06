package DBIx::Skin::DBD::Pg;
use strict;
use warnings;
use base 'DBIx::Skin::DBD::Base';

sub sql_for_unixtime { "TRUNC(EXTRACT('epoch' from NOW()))" }

sub quote    { '"' }
sub name_sep { '.' }

1;

