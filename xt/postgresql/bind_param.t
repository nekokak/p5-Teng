use strict;
use warnings;
use xt::Utils::postgresql;
use Test::More;

use Teng;
use Teng::Schema::Loader;

eval q{
    require DBD::Pg;
    DBD::Pg->import(':pg_types');
};
if ( $@ ) {
    plan skip_all => $@;
}

my $dbh = t::Utils::setup_dbh();

$dbh->do(q{
    CREATE TABLE foo (
        id      serial,
        bar     text,
        baz     bytea,
        PRIMARY KEY (id)
    );        
});

my $schema = Teng::Schema::Loader->load(
    dbh => $dbh,
    namespace => 'Mock::DB',
);
my $db = Teng->new(
    dbh => $dbh,
    schema => $schema,
);

isa_ok( $db, 'Teng' );

my $binary = "\x21\x00\x21";

# normal
my $row = $db->insert('foo', { bar => 'あいうえお', baz => $binary } );

is( $row->bar, 'あいうえお', 'text' );
is( $row->baz, $binary, 'bytea' );

$row = $db->single('foo', { id => 1 });

is( $row->bar, 'あいうえお', 'selected text' );
is( $row->baz, $binary, 'selected bytea' );

# row object
$db->suppress_row_objects(1);

$row = $db->insert('foo', { bar => 'あいうえお', baz => $binary } );

is( $row->{bar}, 'あいうえお', 'row object text' );
is( $row->{baz}, $binary, 'row object bytea' );

$row = $db->single('foo', { id => 2 });

is( $row->{bar}, 'あいうえお', 'selected row object text' );
is( $row->{baz}, $binary, 'selected row object bytea' );

# update
$db->suppress_row_objects(0);

is( $db->update('foo', { baz => $binary . $binary  }, { id => 1 }), 1, 'update' );

$row = $db->single('foo', { id => 1 });
is( $row->baz, $binary . $binary, 'updated bytea' );

# row update
$row = $db->single('foo', { id => 2 });
$row->update( { baz => $binary . $binary } );

$row = $db->single('foo', { id => 2 });
is( $row->baz, $binary . $binary, 'row updated bytea' );

# explicitly type specified
$row = $db->insert('foo', { baz => [ $binary, { pg_type => DBD::Pg::PG_BYTEA } ] } );
is( $row->baz, $binary, 'explicitly type specified bytea' );
$row = $db->single('foo', { id => 3 });
is( $row->baz, $binary, 'selected explicitly type specified' );

done_testing;


