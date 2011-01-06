package DBIx::Skin::Mixin;
use strict;
use warnings;
use Carp ();

sub import {
    my($class, %args) = @_;
    Carp::croak "Usage: use DBIx::Skin::Mixin modules => ['MixinModuleName', 'MixinModuleName2', .... ]"
        unless $args{modules} && ref($args{modules}) eq 'ARRAY';

    my $caller = caller;
    for my $module (@{ $args{modules} }) {
        my $pkg = $module;
        $pkg = __PACKAGE__ . "::$pkg" unless $pkg =~ s/^\+//;

        eval "use $pkg"; ## no critic
        if ($@) {
            Carp::croak $@;
        }

        my $register_methods = $pkg->register_method;
        while (my($method, $code) = each %{ $register_methods }) {
            no strict 'refs';
            *{"$caller\::$method"} = $code;
        }
    }
}

1;

=head1 NAME

DBIx::Skin::Mixin - mixin manager for DBIx::Skin

=head1 SYNOPSIS

  use DBIx::Skin::Mixin modules => ['mixin_module_names'];

=cut

