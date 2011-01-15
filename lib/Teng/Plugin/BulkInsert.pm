package Teng::Plugin::BulkInsert;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/bulk_insert/;

sub bulk_insert {
    my ($self, $table, $args) = @_;

    if ($self->dbh->{Driver}->{Name} eq 'mysql') {
        $self->insert_multi($table, $args);
    } else {
        # use transaction for better performance and atomicity.
        my $txn = $self->txn_scope();
        for my $arg (@$args) {
            # do not run trigger for consistency with mysql.
            $self->insert($table, $arg);
        }
        $txn->commit;
    }
}

1;
__END__

=head1 NAME

Teng::Plugin::BulkInsert - bulk insert helper

=head1 PROVIDED METHODS

=over 4

=item $teng->bulk_insert($table_name, \@rows_data)

Accepts either an arrayref of hashrefs.
each hashref should be a structure suitable
forsubmitting to a Your::Model->insert(...) method.

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

