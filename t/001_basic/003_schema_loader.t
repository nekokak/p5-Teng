use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use Teng;
use Teng::Schema::Loader;

# initialize
my $dbh = DBI->connect('dbi:SQLite:./loader.db', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    create table user (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});

{
    package Mock::DB;
    use parent 'Teng';
}

subtest 'use $dbh' => sub {
    my $db = Teng::Schema::Loader->load(
        dbh       => $dbh,
        namespace => 'Mock::DB',
    );

    isa_ok $db, 'Mock::DB';

    my $user = $db->schema->get_table('user');
    is($user->name, 'user');
    is(join(',', @{$user->primary_keys}), 'user_id');
    is(join(',', @{$user->columns}), 'user_id,name,email,created_on');

    my $row = $db->schema->get_row_class('user');
    is $row, 'Mock::DB::Row::User';

    ok $db->insert('user', { user_id => 1, name => 'inserted' });
    is $db->single('user', { user_id => 1 })->name, 'inserted';
};

subtest 'use connect_info' => sub {
    my $db = Teng::Schema::Loader->load(
        connect_info => ['dbi:SQLite:./loader.db','',''],
        namespace    => 'Mock::DB',
    );

    isa_ok $db, 'Mock::DB';

    my $user = $db->schema->get_table('user');
    is($user->name, 'user');
    is(join(',', @{$user->primary_keys}), 'user_id');
    is(join(',', @{$user->columns}), 'user_id,name,email,created_on');

    my $row = $db->schema->get_row_class('user');
    is $row, 'Mock::DB::Row::User';

    ok $db->insert('user', { user_id => 2, name => 'inserted 2' });
    is $db->single('user', { user_id => 2 })->name, 'inserted 2';
};

unlink './loader.db';
done_testing;

