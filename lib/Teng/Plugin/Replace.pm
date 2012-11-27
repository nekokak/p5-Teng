package Teng::Plugin::Replace;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/replace/;

sub replace {
    my ($self, $table_name, $args) = @_;

    $self->insert($table_name, $args, 'REPLACE INTO');
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

