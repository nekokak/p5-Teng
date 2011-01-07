package DBIx::Skin::DBD::Oracle;
use strict;
use warnings;
use base 'DBIx::Skin::DBD::Base';
use DBIx::Skin::SQL::Oracle;

sub quote    { '"' }
sub name_sep { '.' }
sub query_builder_class { 'DBIx::Skin::SQL::Oracle' }

1;
