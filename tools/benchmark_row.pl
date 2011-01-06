#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw/cmpthese/;
use lib qw{../lib/ ../t/};
use Mock::Basic;
use Mock::BasicRow;

Mock::Basic->setup_test_db;
Mock::BasicRow->setup_test_db;
for my $i (1..1000) {
    Mock::Basic->insert('mock_basic',{
        id   => $i,
        name => 'perl',
    });
    Mock::BasicRow->insert('mock_basic_row',{
        id   => $i,
        name => 'perl',
    });
}

cmpthese(2000, {
    'anon' => sub { Mock::Basic->search('mock_basic')->all},
    'row'  => sub { Mock::BasicRow->search('mock_basic_row')->all },
});

