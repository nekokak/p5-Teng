package Teng::Plugin::BulkInsert;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/bulk_insert/;

warn "IMPORTANT: Teng::Plugin::BulkInsert is DEPRECATED AND *WILL* BE REMOVED. DO NOT USE.\n";

sub bulk_insert {
    my ($self, $table_name, $args) = @_;

    return unless scalar(@{$args||[]});

    if ($self->dbh->{Driver}->{Name} eq 'mysql') {
        my $table = $self->schema->get_table($table_name);
        if (! $table) {
            Carp::croak( "Table definition for $table_name does not exist (Did you declare it in our schema?)" );
        }

        if ( $table->has_deflators ) {
            for my $row (@$args) {
                for my $col (keys %{$row}) {
                    $row->{$col} = $table->call_deflate($col, $row->{$col});
                }
            }
        }

        my ($sql, @binds) = $self->sql_builder->insert_multi( $table_name, $args );
        $self->execute($sql, \@binds);
    } else {
        # use transaction for better performance and atomicity.
        my $txn = $self->txn_scope();
        for my $arg (@$args) {
            # do not run trigger for consistency with mysql.
            $self->insert($table_name, $arg);
        }
        $txn->commit;
    }
}

1;
__END__

=head1 NAME

Teng::Plugin::BulkInsert - (DEPRECATED) Bulk insert helper

=head1 PROVIDED METHODS

=over 4

=item C<$teng-&gt;bulk_insert($table_name, \@rows_data)>

Accepts either an arrayref of hashrefs.
each hashref should be a structure suitable
for submitting to a Your::Model->insert(...) method.

insert many record by bulk.

example:

    Your::Model->bulk_insert('user',[
        {
            id   => 1,
            name => 'nekokak',
        },
        {
            id   => 2,
            name => 'yappo',
        },
        {
            id   => 3,
            name => 'walf443',
        },
    ]);

=back

