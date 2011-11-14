package Teng::Plugin::AutoReconnect;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/_verify_pid disconnect/;

sub _verify_pid {
    my $self = shift;

    if ( !$self->owner_pid || $self->owner_pid != $$ ) {
        $self->reconnect;
    }
    elsif ( my $dbh = $self->{dbh} ) {
        if ( !$dbh->FETCH('Active') || !$dbh->ping ) {
            $self->reconnect;
        }
    }
}

sub disconnect {
    my $self = shift;
    delete $self->{txn_manager};
    # no delete $self->{dbh}
    # because missing dbh then cannot reconnect
    if ( my $dbh = $self->{dbh} ) {
        if ( $self->owner_pid && ($self->owner_pid != $$) ) {
            $dbh->{InactiveDestroy} = 1;
        }
        else {
            $dbh->disconnect;
        }
    }

    $self->owner_pid(undef);
}

1;
__END__

=head1 NAME

Teng::Plugin::AutoReconnect - AutoReconnect dbh

=head1 NAME

    package MyDB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('AutoReconnect');

    package main;
    my $db = MyDB->new(...);
    $db->disconnect;
    $db->single('user', {id => 1}); # reconnect transparency
    if ( fork ) {
        # parent
        $db->single('user', {id => 1}); # use original dbh
    }
    else {
        # child
        $db->single('user', {id => 1}); # reconnect transparency
    }

=head1 DESCRIPTION

This plugin provides reconnect dbh transparency at disconnected and forked.


