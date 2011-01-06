package DBIx::Skinny::DBD::Oracle;
use strict;
use warnings;
use base 'DBIx::Skinny::DBD::Base';
use DBIx::Skinny::SQL::Oracle;

sub sql_for_unixtime {
    "(cast(SYS_EXTRACT_UTC(current_timestamp) as date) - date '1900-01-01') * 24 * 60 * 60";
}

sub quote    { '"' }
sub name_sep { '.' }
sub query_builder_class { 'DBIx::Skinny::SQL::Oracle' }

1;
