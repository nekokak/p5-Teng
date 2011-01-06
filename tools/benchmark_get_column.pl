#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/countit timethese timeit timestr/;
use lib qw{../lib/ ../t/};
use Mock::Basic;

Mock::Basic->setup_test_db;
for my $i (1..5000) {
    Mock::Basic->insert('mock_basic',{
        id   => $i,
        name => 'perl',
    });
}

my $t = countit 2 => sub {
    my $itr = Mock::Basic->search('mock_basic');
    while (my $row = $itr->next) {
        $row->get_column('name');
    }
};

print timestr($t), "\n";

__END__
before:
 2 wallclock secs ( 2.02 usr +  0.00 sys =  2.02 CPU) @  7.43/s (n=15)

after:
 2 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @  7.35/s (n=15)

