use strict;
use warnings;
use utf8;
use xt::Utils::mysql;
use Test::More;
use lib './t';

use Teng;
use Teng::Schema::Loader;

my $dbh = t::Utils->setup_dbh;
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
is(join(',', sort @{$user->columns}), join(',', sort qw/user_id name email created_on/));
is_deeply $user->sql_types, +{
    user_id    => 4,
    name       => 12,
    email      => 12,
    created_on => 4,  
};

my $row = $db->schema->get_row_class('user');
is $row, 'Mock::DB::Row::User';

ok $db->insert('user', { user_id => 1, name => 'inserted' });
is $db->single('user', { user_id => 1 })->name, 'inserted';

done_testing;

