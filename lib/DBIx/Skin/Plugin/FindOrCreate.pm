package DBIx::Skin::Plugin::FindOrCreate;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/find_or_create/;

sub find_or_create {
    my ($self, $table, $args) = @_;
    my $row = $self->single($table, $args);
    return $row if $row;
    $self->insert($table, $args)->refetch;
}

1;

