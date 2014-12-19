use strict;
use warnings;
use Test::More;
use DBI;
use Teng;
use Teng::Schema::Dumper;

# initialize
my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    create table user1 (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});
$dbh->do(q{
    create table user2 (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});
$dbh->do(q{
    create table user3 (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});


subtest "dump all tables" => sub {
    # generate schema and eval.
    my $code = Teng::Schema::Dumper->dump(
        dbh       => $dbh,
        namespace => 'Mock::DB',
        inflate   => +{
            user1 => q|
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

    for my $table_name (qw/user1 user2 user3/) {
        my $user = $db->schema->get_table($table_name);
        is($user->name, $table_name);
        is(join(',', @{$user->primary_keys}), 'user_id');
        is(join(',', @{$user->columns}), 'user_id,name,email,created_on');
    }

    my $row_class = $db->schema->get_row_class('user1');
    isa_ok $row_class, 'Mock::DB::Row::User1';

    my $row = $db->insert('user1', +{name => 'nekokak', email => 'nekokak@gmail.com'});
    is $row->email, 'nekokak@gmail.com_deflate_inflate';
    is $row->get_column('email'), 'nekokak@gmail.com_deflate';
};

subtest "dump single table" => sub {
    # generate schema and eval.
    my $code = Teng::Schema::Dumper->dump(
        dbh       => $dbh,
        namespace => 'Mock::DB',
        tables => 'user1',
    );
    note $code;
    like $code, qr/user1/;
    unlike $code, qr/user2/;
    unlike $code, qr/user3/;
};

subtest "dump multiple tables" => sub {
    # generate schema and eval.
    my $code = Teng::Schema::Dumper->dump(
        dbh       => $dbh,
        namespace => 'Mock::DB',
        tables => [qw/user1 user2/],
    );
    note $code;
    like $code, qr/user1/;
    like $code, qr/user2/;
    unlike $code, qr/user3/;
};
subtest "dump with base_row_class" => sub {
    # generate schema and eval.
    my $code = Teng::Schema::Dumper->dump(
        dbh            => $dbh,
        namespace      => 'Mock::DB',
        base_row_class => 'Mock::DB::Row',
    );
    note $code;
    like $code, qr/base_row_class 'Mock::DB::Row';\n/;
};

done_testing;
