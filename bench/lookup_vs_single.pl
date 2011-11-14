#! /usr/bin/perl
use strict;
use warnings;
use Benchmark qw(:all :hireswallclock);
use Data::Dumper;
use Test::Mock::Guard qw/mock_guard/;

{
    package Bench;
    use parent 'Teng';
    __PACKAGE__->load_plugin('Lookup');

    package Bench::Schema;
    use Teng::Schema::Declare;
    table {
        name 'user';
        pk   'id';
        columns qw/name age/;
    };
}
my $gurad = mock_guard('DBI::st' => +{fetchrow_hashref => +{id => 1, name => 'nekokak', age => 33}});

my $db = Bench->new({connect_info => ['dbi:SQLite::memory:','','']});

$db->do( q{DROP TABLE IF EXISTS user} );
$db->do(q{
    CREATE TABLE user (
        id   INT PRIMARY KEY,
        name TEXT,
        age  INT
    );
});

my $row = $db->single('user', { id => 1 });

cmpthese(10000 => +{
    single => sub {$db->single('user', +{id => 1})},
    lookup => sub {$db->lookup('user', +{id => 1})},
}, 'all');

__END__
Benchmark: timing 10000 iterations of lookup, single...
    lookup: 1.89032 wallclock secs ( 1.55 usr  0.29 sys +  0.00 cusr  0.00 csys =  1.84 CPU) @ 5434.78/s (n=10000)
    single: 3.64415 wallclock secs ( 3.30 usr  0.30 sys +  0.00 cusr  0.00 csys =  3.60 CPU) @ 2777.78/s (n=10000)
         Rate single lookup
single 2778/s     --   -49%
lookup 5435/s    96%     --

