#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/countit timethese timeit timestr/;
use lib qw{../lib/ ../t/};
use Mock::UTF8;

Mock::UTF8->setup_test_db;
for my $i (1..5000) {
    Mock::UTF8->insert('mock_utf8',{
        id   => $i,
        name => 'perl',
    });
}

my $t = countit 2 => sub {
    my $itr = Mock::UTF8->search('mock_utf8');
    while (my $row = $itr->next) {
        $row->get_column('name');
    }
};

print timestr($t), "\n";

__END__
before:
 2 wallclock secs ( 1.98 usr +  0.02 sys =  2.00 CPU) @  5.00/s (n=10)
 3 wallclock secs ( 2.16 usr +  0.01 sys =  2.17 CPU) @  5.07/s (n=11)
 3 wallclock secs ( 2.15 usr +  0.01 sys =  2.16 CPU) @  5.09/s (n=11)
 2 wallclock secs ( 2.15 usr +  0.01 sys =  2.16 CPU) @  5.09/s (n=11)
 3 wallclock secs ( 2.15 usr +  0.01 sys =  2.16 CPU) @  5.09/s (n=11)
after:
 2 wallclock secs ( 2.02 usr +  0.01 sys =  2.03 CPU) @  5.42/s (n=11)
 2 wallclock secs ( 2.01 usr +  0.00 sys =  2.01 CPU) @  5.47/s (n=11)
 2 wallclock secs ( 2.02 usr +  0.01 sys =  2.03 CPU) @  5.42/s (n=11)
 2 wallclock secs ( 2.02 usr +  0.01 sys =  2.03 CPU) @  5.42/s (n=11)
 2 wallclock secs ( 2.02 usr +  0.00 sys =  2.02 CPU) @  5.45/s (n=11)

