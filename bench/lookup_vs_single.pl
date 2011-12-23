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
    __PACKAGE__->load_plugin('SingleBySQL');

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
    dbi           => sub {$dbh->selectrow_hashref('SELECT id,name,age FROM user where id = ?', undef, 1)},
    single        => sub {$db->single('user', +{id => 1})},
    single_by_sql => sub {$db->single_by_sql('SELECT id,name,age FROM user WHERE id = ?', [1], 'user')},
    lookup        => sub {$db->lookup('user', +{id => 1})},
}, 'all');

__END__
Benchmark: timing 10000 iterations of dbi, lookup, single, single_by_sql...
       dbi: 0.543471 wallclock secs ( 0.50 usr  0.01 sys +  0.00 cusr  0.00 csys =  0.51 CPU) @ 19607.84/s (n=10000)
    lookup: 0.808071 wallclock secs ( 0.78 usr  0.00 sys +  0.00 cusr  0.00 csys =  0.78 CPU) @ 12820.51/s (n=10000)
    single: 1.67938 wallclock secs ( 1.57 usr  0.00 sys +  0.00 cusr  0.00 csys =  1.57 CPU) @ 6369.43/s (n=10000)
single_by_sql: 0.769787 wallclock secs ( 0.74 usr  0.00 sys +  0.00 cusr  0.00 csys =  0.74 CPU) @ 13513.51/s (n=10000)
                 Rate        single        lookup single_by_sql           dbi
single         6369/s            --          -50%          -53%          -68%
lookup        12821/s          101%            --           -5%          -35%
single_by_sql 13514/s          112%            5%            --          -31%
dbi           19608/s          208%           53%           45%            --
