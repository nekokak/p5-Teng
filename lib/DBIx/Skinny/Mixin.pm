package DBIx::Skinny::Mixin;
use strict;
use warnings;
use Carp ();

sub import {
    my($class, %args) = @_;
    Carp::croak "Usage: use DBIx::Skinny::Mixin modules => ['MixinModuleName', 'MixinModuleName2', .... ]"
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

DBIx::Skinny::Mixin - mixin manager for DBIx::Skinny

=head1 SYNOPSIS

  use DBIx::Skinny::Mixin modules => ['mixin_module_names'];

=cut

