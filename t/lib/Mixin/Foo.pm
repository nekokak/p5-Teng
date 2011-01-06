package Mixin::Foo;
use strict;
use warnings;

sub register_method {
    +{
        foo => sub { 'foo' },
    };
}

1;
