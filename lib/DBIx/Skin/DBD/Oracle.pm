package DBIx::Skin::DBD::Oracle;
use strict;
use warnings;
use base 'DBIx::Skin::DBD::Base';
use DBIx::Skin::SQL::Oracle;

sub sql_for_unixtime {
    "(cast(SYS_EXTRACT_UTC(current_timestamp) as date) - date '1900-01-01') * 24 * 60 * 60";
}

sub quote    { '"' }
sub name_sep { '.' }
sub query_builder_class { 'DBIx::Skin::SQL::Oracle' }

1;
