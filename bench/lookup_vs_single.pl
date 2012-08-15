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

my $dbh = $db->dbh;

cmpthese(10000 => +{
    dbi             => sub {$dbh->selectrow_hashref('SELECT id,name,age FROM user where id = ?', undef, 1)},
    single          => sub {$db->single('user', +{id => 1})},
    single_by_sql   => sub {$db->single_by_sql('SELECT id,name,age FROM user WHERE id = ?', [1], 'user')},
    single_named   => sub {$db->single_named('SELECT id,name,age FROM user WHERE id = :id', {id => 1}, 'user')},
    lookup          => sub {$db->lookup('user', +{id => 1})},
    lookup_arrayref => sub {$db->lookup('user', [id => 1])},
}, 'all');

__END__

Benchmark: timing 10000 iterations of dbi, lookup, lookup_arrayref, single, single_by_sql, single_named...
       dbi: 0.681385 wallclock secs ( 0.50 usr  0.00 sys +  0.00 cusr  0.00 csys =  0.50 CPU) @ 20000.00/s (n=10000)
    lookup: 1.53734 wallclock secs ( 1.04 usr  0.00 sys +  0.00 cusr  0.00 csys =  1.04 CPU) @ 9615.38/s (n=10000)
lookup_arrayref: 1.40989 wallclock secs ( 1.02 usr  0.00 sys +  0.00 cusr  0.00 csys =  1.02 CPU) @ 9803.92/s (n=10000)
    single: 2.49036 wallclock secs ( 1.57 usr  0.01 sys +  0.00 cusr  0.00 csys =  1.58 CPU) @ 6329.11/s (n=10000)
single_by_sql: 1.09325 wallclock secs ( 0.76 usr  0.00 sys +  0.00 cusr  0.00 csys =  0.76 CPU) @ 13157.89/s (n=10000)
single_named: 1.23624 wallclock secs ( 0.86 usr  0.00 sys +  0.00 cusr  0.00 csys =  0.86 CPU) @ 11627.91/s (n=10000)
                   Rate single lookup lookup_arrayref single_named single_by_sql  dbi
single           6329/s     --   -34%            -35%         -46%          -52% -68%
lookup           9615/s    52%     --             -2%         -17%          -27% -52%
lookup_arrayref  9804/s    55%     2%              --         -16%          -25% -51%
single_named    11628/s    84%    21%             19%           --          -12% -42%
single_by_sql   13158/s   108%    37%             34%          13%            -- -34%
dbi             20000/s   216%   108%            104%          72%           52%   --
