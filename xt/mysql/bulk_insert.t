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
        user_id integer primary key
    );
});

my $schema = Teng::Schema::Loader->load(
    dbh       => $dbh,
    namespace => 'Mock::DB',
);

{
    package Mock::DB;
    use parent 'Teng';
    __PACKAGE__->load_plugin('BulkInsert');
}

my $db = Mock::DB->new(
    schema => $schema,
    dbh    => $dbh,
);
my $user = $db->schema->get_table('user');

eval {
    $db->bulk_insert('user',);
};
ok not $@;

eval {
    $db->bulk_insert('user', []);
};
ok not $@;

my @ids = qw( 1 2 3 4 5 6 7 8 9 );
my @rows = map { +{ user_id => $_ } } @ids;
$db->bulk_insert('user', \@rows);

for my $id (@ids) {
    my $row = $db->single('user', { user_id => $id });
    is($row->user_id, $id, "found: $id");
}

done_testing;
