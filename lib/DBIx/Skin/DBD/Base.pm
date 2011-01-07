package DBIx::Skin::DBD::Base;
use strict;
use warnings;
use DBIx::Skin::SQL;

sub sql_for_unixtime { time() }

sub quote    { '`' }
sub name_sep { '.' }

sub bulk_insert {
    my ($skinny, $table, $args) = @_;

    return unless @$args;

    my $txn = $skinny->txn_scope;

        for my $arg ( @{$args} ) {
            $skinny->_insert_or_replace(0, $table, $arg);
        }

    $txn->commit;

    return 1;
}

sub query_builder_class { 'DBIx::Skin::SQL' }
sub bind_param_attributes {}

1;

