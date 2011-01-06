#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/countit timethese timeit timestr/;
use lib qw{../lib/ ../t/};
use Mock::Basic;

Mock::Basic->setup_test_db;

my @rows;
for my $i (1..10000) {
    push @rows, +{
        id   => $i,
        name => 'perl',
    };
}

my $t = countit 2 => sub {
    Mock::Basic->bulk_insert('mock_basic', \@rows)
};

print timestr($t), "\n";

__END__
not begin_work:
  40 wallclock secs (38.56 usr +  0.57 sys = 39.13 CPU) @  0.03/s (n=1)
begin_work:
  39 wallclock secs (38.47 usr +  0.09 sys = 38.56 CPU) @  0.03/s (n=1)

