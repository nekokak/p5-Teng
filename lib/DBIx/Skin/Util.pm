package DBIx::Skin::Util;
use strict;
use warnings;

# XXX: need this module? by nekokak@20110111

sub camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

1;

