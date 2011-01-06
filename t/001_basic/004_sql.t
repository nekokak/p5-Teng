use strict;
use warnings;

use DBIx::Skinny::SQL;
use Test::More;

my $stmt = ns();
ok($stmt, 'Created SQL object');

## Testing FROM
$stmt->from([ 'foo' ]);
is($stmt->as_sql, "FROM foo\n");

$stmt->from([ 'foo', 'bar' ]);
is($stmt->as_sql, "FROM foo, bar\n");

## Testing JOINs
$stmt->from([]);
$stmt->joins([]);
$stmt->add_join(foo => { type => 'inner', table => 'baz',
                         condition => 'foo.baz_id = baz.baz_id' });
is($stmt->as_sql, "FROM foo INNER JOIN baz ON foo.baz_id = baz.baz_id\n");

$stmt->from([ 'bar' ]);
is($stmt->as_sql, "FROM foo INNER JOIN baz ON foo.baz_id = baz.baz_id, bar\n");

$stmt->from([]);
$stmt->joins([]);
$stmt->add_join(foo => [
        { type => 'inner', table => 'baz b1',
          condition => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1' },
        { type => 'left', table => 'baz b2',
          condition => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2' },
    ]);
is $stmt->as_sql, "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2\n";

# test case for bug found where add_join is called twice
$stmt->joins([]);
$stmt->add_join(foo => [
        { type => 'inner', table => 'baz b1',
          condition => 'foo.baz_id = b1.baz_id AND b1.quux_id = 1' },
]);
$stmt->add_join(foo => [
        { type => 'left', table => 'baz b2',
          condition => 'foo.baz_id = b2.baz_id AND b2.quux_id = 2' },
    ]);
is $stmt->as_sql, "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2\n";

# test case adding another table onto the whole mess
$stmt->add_join(quux => [
        { type => 'inner', table => 'foo f1',
          condition => 'f1.quux_id = quux.q_id'}
    ]);

is $stmt->as_sql, "FROM foo INNER JOIN baz b1 ON foo.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON foo.baz_id = b2.baz_id AND b2.quux_id = 2 INNER JOIN foo f1 ON f1.quux_id = quux.q_id\n";

## Testing GROUP BY
$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->group({ column => 'baz' });
is($stmt->as_sql, "FROM foo\nGROUP BY baz\n", 'single bare group by');

$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->group({ column => 'baz', desc => 'DESC' });
is($stmt->as_sql, "FROM foo\nGROUP BY baz DESC\n", 'single group by with desc');

$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->group([ { column => 'baz' }, { column => 'quux' }, ]);
is($stmt->as_sql, "FROM foo\nGROUP BY baz, quux\n", 'multiple group by');

$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->group([ { column => 'baz',  desc => 'DESC' },
               { column => 'quux', desc => 'DESC' }, ]);
is($stmt->as_sql, "FROM foo\nGROUP BY baz DESC, quux DESC\n", 'multiple group by with desc');

## Testing ORDER BY
$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->order({ column => 'baz', desc => 'DESC' });
is($stmt->as_sql, "FROM foo\nORDER BY baz DESC\n", 'single order by');

$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->order([ { column => 'baz',  desc => 'DESC' },
               { column => 'quux', desc => 'ASC'  }, ]);
is($stmt->as_sql, "FROM foo\nORDER BY baz DESC, quux ASC\n", 'multiple order by');

## Testing GROUP BY plus ORDER BY
$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->group({ column => 'quux' });
$stmt->order({ column => 'baz', desc => 'DESC' });
is($stmt->as_sql, "FROM foo\nGROUP BY quux\nORDER BY baz DESC\n", 'group by with order by');

## Testing LIMIT and OFFSET
$stmt = ns();
$stmt->from([ 'foo' ]);
$stmt->limit(5);
is($stmt->as_sql, "FROM foo\nLIMIT 5\n");
$stmt->offset(10);
is($stmt->as_sql, "FROM foo\nLIMIT 5 OFFSET 10\n");
$stmt->limit("  15g");  ## Non-numerics should cause an error
{
    my $sql = eval { $stmt->as_sql };
    like($@, qr/Non-numerics/, "bogus limit causes as_sql assertion");
}

## Testing WHERE
$stmt = ns(); $stmt->add_where(foo => 'bar');
is($stmt->as_sql_where, "WHERE (foo = ?)\n");
is(scalar @{ $stmt->bind }, 1);
is($stmt->bind->[0], 'bar');

$stmt = ns(); $stmt->add_where(foo => [ 'bar', 'baz' ]);
is($stmt->as_sql_where, "WHERE (foo IN (?,?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns(); $stmt->add_where(foo => { in => [ 'bar', 'baz' ]});
is($stmt->as_sql_where, "WHERE (foo IN (?,?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns(); $stmt->add_where(foo => { 'not in' => [ 'bar', 'baz' ]});
is($stmt->as_sql_where, "WHERE (foo NOT IN (?,?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns(); $stmt->add_where(foo => { '!=' => 'bar' });
is($stmt->as_sql_where, "WHERE (foo != ?)\n");
is(scalar @{ $stmt->bind }, 1);
is($stmt->bind->[0], 'bar');

$stmt = ns(); $stmt->add_where(foo => \'IS NOT NULL');
is($stmt->as_sql_where, "WHERE (foo IS NOT NULL)\n");
is(scalar @{ $stmt->bind }, 0);

$stmt = ns();
$stmt->add_where(foo => 'bar');
$stmt->add_where(baz => 'quux');
is($stmt->as_sql_where, "WHERE (foo = ?) AND (baz = ?)\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'quux');

$stmt = ns();
$stmt->add_where(foo => [ { '>' => 'bar' },
                          { '<' => 'baz' } ]);
is($stmt->as_sql_where, "WHERE ((foo > ?) OR (foo < ?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns();
$stmt->add_where(foo => [ -and => { '>' => 'bar' },
                                  { '<' => 'baz' } ]);
is($stmt->as_sql_where, "WHERE ((foo > ?) AND (foo < ?))\n");
is(scalar @{ $stmt->bind }, 2);
is($stmt->bind->[0], 'bar');
is($stmt->bind->[1], 'baz');

$stmt = ns();
$stmt->add_where(foo => [ -and => 'foo', 'bar', 'baz']);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?))\n");
is(scalar @{ $stmt->bind }, 3);
is($stmt->bind->[0], 'foo');
is($stmt->bind->[1], 'bar');
is($stmt->bind->[2], 'baz');

## Testing WHERE-raw
$stmt = ns(); $stmt->add_where_raw('exists(SELECT * WHERE type=?)', [5]);
is($stmt->as_sql_where, "WHERE (exists(SELECT * WHERE type=?))\n");
is(scalar @{ $stmt->bind }, 1);
is($stmt->bind->[0], '5');

$stmt = ns(); $stmt->add_where_raw('hoge is not null');
is($stmt->as_sql_where, "WHERE (hoge is not null)\n");
is(scalar @{ $stmt->bind }, 0);

{
    # nested stmt case
    my $nested_stmt = ns();
    $nested_stmt->add_select('*');
    $nested_stmt->from(['foo']);
    $nested_stmt->add_where(type => [3, 4, 5]);
    $stmt = ns(); $stmt->add_where_raw(sprintf('exists(%s)', $nested_stmt->as_sql), $nested_stmt->bind);
    is($stmt->as_sql_where, "WHERE (exists(SELECT *\nFROM foo\nWHERE (type IN (?,?,?))\n))\n");
    is(scalar @{ $stmt->bind }, 3);
    is_deeply($stmt->bind, [3, 4, 5]);
}

## regression bug. modified parameters
my %terms = ( foo => [-and => 'foo', 'bar', 'baz']);
$stmt = ns();
$stmt->add_where(%terms);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?))\n");
$stmt->add_where(%terms);
is($stmt->as_sql_where, "WHERE ((foo = ?) AND (foo = ?) AND (foo = ?)) AND ((foo = ?) AND (foo = ?) AND (foo = ?))\n");

$stmt = ns();
$stmt->add_select(foo => 'foo');
$stmt->add_select('bar');
$stmt->from([ qw( baz ) ]);
is($stmt->as_sql, "SELECT foo, bar\nFROM baz\n");

$stmt = ns();
$stmt->add_select('f.foo' => 'foo');
$stmt->add_select('COUNT(*)' => 'count');
$stmt->from([ qw( baz ) ]);
is($stmt->as_sql, "SELECT f.foo, COUNT(*) AS count\nFROM baz\n");
my $map = $stmt->select_map;
is(scalar(keys %$map), 2);
is($map->{'f.foo'}, 'foo');
is($map->{'COUNT(*)'}, 'count');

# HAVING
$stmt = ns();
$stmt->add_select(foo => 'foo');
$stmt->add_select('COUNT(*)' => 'count');
$stmt->from([ qw(baz) ]);
$stmt->add_where(foo => 1);
$stmt->group({ column => 'baz' });
$stmt->order({ column => 'foo', desc => 'DESC' });
$stmt->limit(2);
$stmt->add_having(count => 2);

is($stmt->as_sql, <<SQL);
SELECT foo, COUNT(*) AS count
FROM baz
WHERE (foo = ?)
GROUP BY baz
HAVING (COUNT(*) = ?)
ORDER BY foo DESC
LIMIT 2
SQL

# DISTINCT
$stmt = ns();
$stmt->add_select(foo => 'foo');
$stmt->from([ qw(baz) ]);
is($stmt->as_sql, "SELECT foo\nFROM baz\n", "DISTINCT is absent by default");
$stmt->distinct(1);
is($stmt->as_sql, "SELECT DISTINCT foo\nFROM baz\n", "we can turn on DISTINCT");

# index hint
$stmt = ns();
$stmt->add_select(foo => 'foo');
$stmt->from([ qw(baz) ]);
is($stmt->as_sql, "SELECT foo\nFROM baz\n", "index hint is absent by default");
$stmt->add_index_hint('baz' => { type => 'USE', list => ['index_hint']});
is($stmt->as_sql, "SELECT foo\nFROM baz USE INDEX (index_hint)\n", "we can turn on USE INDEX");

# index hint with joins
$stmt->joins([]);
$stmt->from([]);
$stmt->add_join(baz => { type => 'inner', table => 'baz',
                         condition => 'baz.baz_id = foo.baz_id' });
is($stmt->as_sql, "SELECT foo\nFROM baz USE INDEX (index_hint) INNER JOIN baz ON baz.baz_id = foo.baz_id\n", 'USE INDEX with JOIN');
$stmt->from([]);
$stmt->joins([]);
$stmt->add_join(baz => [
        { type => 'inner', table => 'baz b1',
          condition => 'baz.baz_id = b1.baz_id AND b1.quux_id = 1' },
        { type => 'left', table => 'baz b2',
          condition => 'baz.baz_id = b2.baz_id AND b2.quux_id = 2' },
    ]);
is($stmt->as_sql, "SELECT foo\nFROM baz USE INDEX (index_hint) INNER JOIN baz b1 ON baz.baz_id = b1.baz_id AND b1.quux_id = 1 LEFT JOIN baz b2 ON baz.baz_id = b2.baz_id AND b2.quux_id = 2\n", 'USE INDEX with JOINs');

$stmt = ns();
$stmt->add_select(foo => 'foo');
$stmt->from([ qw(baz) ]);
$stmt->comment("mycomment");
is($stmt->as_sql, "SELECT foo\nFROM baz\n-- mycomment");

$stmt->comment("\nbad\n\nmycomment");
is($stmt->as_sql, "SELECT foo\nFROM baz\n-- bad", "correctly untainted");

$stmt->comment("G\\G");
is($stmt->as_sql, "SELECT foo\nFROM baz\n-- G", "correctly untainted");

subtest 'add_complex_where' => sub {
    subtest 'OR' => sub {
        my $sql = ns();
        $sql->from(['baz']);
        $sql->add_select('foo' => 'foo');
        $sql->add_complex_where([-or => { 'foo' => "hoge" }, { 'foo' => "fuga" }]);
        is($sql->as_sql, "SELECT foo\nFROM baz\nWHERE (foo = ?) OR (foo = ?)\n", "SQL OK");
        is(@{ $sql->bind }, 2, "bind variable num ok");
        is($sql->bind->[0], "hoge");
        is($sql->bind->[1], "fuga");

        done_testing;
    };

    subtest 'nesting' => sub {
        my $sql = ns();
        $sql->from(['baz']);
        $sql->add_select('foo' => 'foo');
        $sql->add_complex_where([ -and => [-or => { 'foo' => "hoge" }, { 'foo' => "fuga" }], { 'bar' => "baz" }]);
        is($sql->as_sql, "SELECT foo\nFROM baz\nWHERE ((foo = ?) OR (foo = ?)) AND (bar = ?)\n", "SQL OK");
        is(@{ $sql->bind }, 3, "bind variable num ok");
        is($sql->bind->[0], "hoge");
        is($sql->bind->[1], "fuga");
        is($sql->bind->[2], "baz");

        done_testing;
    };

    done_testing;
};

subtest join_with_using => sub {
    my $sql = ns();
    $sql->from([]);
    $sql->add_join(foo => [
        {
            type => 'inner', table => 'baz',
            condition => [qw/ hoge_id fuga_id /],
        },
    ] );

    is $sql->as_sql, "FROM foo INNER JOIN baz USING (hoge_id, fuga_id)\n";

    done_testing;
};

sub ns { DBIx::Skinny::SQL->new }

done_testing;
