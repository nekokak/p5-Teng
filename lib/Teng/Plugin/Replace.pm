package Teng::Plugin::Replace;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/replace/;

sub replace {
    my ($self, $table_name, $args) = @_;

    my $table = $self->schema->get_table($table_name);

    for my $col (keys %{$args}) {
        $args->{$col} = $table->call_deflate($col, $args->{$col});
    }

    my ($sql, @binds) = $self->sql_builder->insert( $table_name, $args, { prefix => 'REPLACE' } );
    $self->_execute($sql, \@binds, $table_name);

    my $pk = $table->primary_keys();
    if (scalar(@$pk) == 1 && not defined $args->{$pk->[0]}) {
        $args->{$pk->[0]} = $self->_last_insert_id($table_name);
    }

    return $args if $self->suppress_row_objects;

    $table->row_class->new(
        {
            row_data   => $args,
            teng       => $self,
            table_name => $table_name,
        }
    );
}

1;
__END__

=head1 NAME

Teng::Plugin::Replace - add replace for Teng

=head1 PROVIDED METHODS

=over 4

=item $teng->replace($table_name, \%rows_data);

recoed by replace.

example:

    Your::Model->replace('user',
        {
            id   => 3,
            name => 'walf443',
        },
    );

=back

