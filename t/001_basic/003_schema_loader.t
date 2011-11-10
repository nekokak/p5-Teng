use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use Teng;
use Teng::Schema::Loader;

# initialize
my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    create table user (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});

my $schema = Teng::Schema::Loader->load(
    dbh       => $dbh,
    namespace => 'Mock::DB',
);

{
    package Mock::DB;
    use parent 'Teng';
}

my $db = Mock::DB->new(
    schema => $schema,
    dbh    => $dbh,
);
my $user = $db->schema->get_table('user');
is($user->name, 'user');
is(join(',', @{$user->primary_keys}), 'user_id');
is(join(',', @{$user->columns}), 'user_id,name,email,created_on');

my $row = $db->schema->get_row_class('user');
is $row, 'Mock::DB::Row::User';

ok $db->insert('user', { user_id => 1, name => 'inserted' });
is $db->single('user', { user_id => 1 })->name, 'inserted';

done_testing;

