#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/countit timethese timeit timestr/;
use lib qw{../lib/ ../t/};
use Mock::Basic;

Mock::Basic->setup_test_db;
for my $i (1..1000) {
    Mock::Basic->insert('mock_basic',{
        id   => $i,
        name => 'perl',
    });
}

my $t = countit 2 => sub {
    Mock::Basic->search('mock_basic')->all
};

print timestr($t), "\n";

__END__
2008-12-19 21:55
 3 wallclock secs ( 2.15 usr +  0.00 sys =  2.15 CPU) @ 24.19/s (n=52)
2008-12-25 01:17
 2 wallclock secs ( 2.01 usr +  0.01 sys =  2.02 CPU) @ 29.21/s (n=59)
2008-01-02 15:14
 2 wallclock secs ( 2.15 usr +  0.00 sys =  2.15 CPU) @ 28.84/s (n=62)
2008-01-03 14:35
 2 wallclock secs ( 2.00 usr +  0.01 sys =  2.01 CPU) @ 43.28/s (n=87)
2008-01-03 14:50
 2 wallclock secs ( 2.00 usr +  0.00 sys =  2.00 CPU) @ 43.50/s (n=87)
2008-01-03 15:36
 2 wallclock secs ( 2.01 usr +  0.00 sys =  2.01 CPU) @ 43.28/s (n=87)
2008-01-04 19:56
 2 wallclock secs ( 2.00 usr +  0.00 sys =  2.00 CPU) @ 43.50/s (n=87)
2009-02-10 23:10
 2 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 33.80/s (n=73)
2009-02-10 23:16
 2 wallclock secs ( 2.11 usr +  0.00 sys =  2.11 CPU) @ 39.34/s (n=83)

