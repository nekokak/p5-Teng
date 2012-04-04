package
  Teng::Plugin::ArgsTest;

use strict;
use warnings;

our @EXPORT = qw/args_class args_opt/;
my %args;

sub init {
    my ($pkg, $class, $opt) = @_;
    $args{class} = $class;
    $args{opt} = $opt;
}

sub args_class {
    my ($self) = @_;
    return $args{class};
}

sub args_opt {
    my ($self) = @_;
    return $args{opt};
}

1;

