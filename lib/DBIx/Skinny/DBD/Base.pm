package DBIx::Skinny::DBD::Base;
use strict;
use warnings;
use DBIx::Skinny::SQL;

sub sql_for_unixtime { time() }

sub quote    { '`' }
sub name_sep { '.' }

sub bulk_insert {
    my ($skinny, $table, $args) = @_;

    return unless @$args;

    my $txn; $txn = $skinny->txn_scope unless $skinny->_attributes->{active_transaction} != 0;

        for my $arg ( @{$args} ) {
            $skinny->_insert_or_replace(0, $table, $arg);
        }

    $txn->commit if $txn;

    return 1;
}

sub query_builder_class { 'DBIx::Skinny::SQL' }
sub bind_param_attributes {}

1;

