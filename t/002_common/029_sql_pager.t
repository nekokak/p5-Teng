use strict;
use warnings;
use utf8;
use t::Utils;
use Test::More;
use DBI;

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1, AutoCommit => 1});
$dbh->do(q{CREATE TABLE foo (bar integer)});
$dbh->do(q{BEGIN;});
for my $i (1..35) {
    $dbh->do(q{INSERT INTO foo (bar) VALUES (?)}, {}, $i);
}
$dbh->do(q{COMMIT;});

{
    package My::DB::Schema;
    use parent qw/Teng::Schema/;
}
{
    package My::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin(qw/SQLPager/);
}

my $db = My::DB->new(dbh => $dbh, schema => My::DB::Schema->new());
subtest 'first page' => sub {
    my ($rows, $pager) = $db->search_by_sql_with_pager(q{SELECT * FROM foo ORDER BY bar}, [], {page => 1, rows => 20});
    is(join(',', map { $_->bar } @$rows), '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20');
};
subtest 'second page' => sub {
    my ($rows, $pager) = $db->search_by_sql_with_pager(q{SELECT * FROM foo ORDER BY bar}, [], {page => 2, rows => 20});
    is(join(',', map { $_->bar } @$rows), '21,22,23,24,25,26,27,28,29,30,31,32,33,34,35');
};

done_testing;

