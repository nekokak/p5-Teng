package Teng::Plugin::FindOrCreateBy;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/find_or_create_by/;

sub find_or_create_by {
    my ($self, $table, $args, $cb) = @_;
    my $row = $self->single($table, $args);
    return $row if $row;
    $args = $cb->($args) if ref $cb eq 'CODE';
    $self->insert($table, $args)->refetch;
}

1;

__END__

=head1 NAME

Teng::Plugin::FindOrCreateBy - provide find_or_create_by method for your Teng class.

=head1 NAME

    package MyDB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('FindOrCreateBy');

    package main;
    my $db = MyDB->new(...);
    my $row = $db->find_or_create_by('user',{name => 'lestrrat'}, sub {
        my $user = shift;
        $user->{age} = 20;
        return $user;
    });

=head1 DESCRIPTION

This plugin provides find_or_create_by method.

=head1 METHODS

=over 4

=item $row = $db->find_or_create_by($table[, \%args, \&cb]])

I<$table> table name for counting

I<\%args> : HashRef for row data.

|<\&cb> : Callback function to modify row data for creating

=back