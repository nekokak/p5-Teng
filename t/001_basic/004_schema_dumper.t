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
    inflate   => +{
        user => q|
            inflate 'email' => sub {
                my ($col_value) = @_;
                $col_value . '_inflate';
            };
            deflate 'email' => sub {
                my ($col_value) = @_;
                $col_value . '_deflate';
            };
        |,
    },
);
note $code;
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

my $row_class = $db->schema->get_row_class('user');
isa_ok $row_class, 'Mock::DB::Row::User';

my $row = $db->insert('user', +{name => 'nekokak', email => 'nekokak@gmail.com'});
is $row->email, 'nekokak@gmail.com_deflate_inflate';
is $row->get_column('email'), 'nekokak@gmail.com_deflate';

done_testing;

