use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use Teng;
use Teng::Schema::Dumper;

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


# generate schema and eval.
my $code = Teng::Schema::Dumper->dump(
    dbh       => $dbh,
    namespace => 'Mock::DB',
);
my $schema = eval $code;
::ok !$@, 'no syntax error';
diag $@ if $@;

{
    package Mock::DB;
    use parent 'Teng';
}

my $db = Mock::DB->new(dbh => $dbh);
my $user = $db->schema->get_table('user');
is($user->name, 'user');
is(join(',', @{$user->primary_keys}), 'user_id');
is(join(',', @{$user->columns}), 'user_id,name,email,created_on');

my $row = $db->schema->get_row_class('user');
isa_ok $row, 'Mock::DB::Row::User';

done_testing;

