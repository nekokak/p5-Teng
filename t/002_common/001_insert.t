use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
my $db_with_strict_sql_builder = Mock::Basic->new({dbh => $dbh, sql_builder_args => { strict => 1 }});
$db->setup_test_db;

subtest 'insert mock_basic data/ insert method' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'Teng::Row';
    is $row->name, 'perl';
};

subtest 'insert with strict sql builder' => sub {
    my $row = $db_with_strict_sql_builder->insert('mock_basic',{
        id   => 5,
        name => 'python',
    });
    isa_ok $row, 'Teng::Row';
    is $row->name, 'python';
};

subtest 'scalar ref' => sub {
    $db->suppress_row_objects(0);
    my $row = $db->insert('mock_basic',{
        id   => 4,
        name => \"upper('c')",
    });
    is $row->id, 4;
    is $row->name, 'C';
};

subtest 'insert with suppress_row_objects off' => sub {
    $db->suppress_row_objects(1);
    my $row = $db->insert('mock_basic',{
        id   => 2,
        name => 'xs',
    });
    isa_ok $row, 'HASH';
    is $row->{name}, 'xs';
};

SKIP: {
    skip "last_insert_id doesn't work when explicitly inserting id in Pg", 1 if $dbh->{Driver}->{Name} eq 'Pg';
    subtest 'fast_insert' => sub {

        my $last_insert_id = $db->fast_insert('mock_basic',{
            id   => 3,
            name => 'ruby',
        });
        is $last_insert_id, 3;
    };
}

subtest 'fast_insert with pkey not named "id"' => sub {
    my $last_insert_id = $db->fast_insert('mock_basic_anotherpkey',{
        name => 'ruby',
    });
    is $last_insert_id, 1;

    $last_insert_id = $db->fast_insert('mock_basic_anotherpkey',{
        name => 'perl',
    });
    is $last_insert_id, 2;
};

subtest 'insert returning row for mysql_insertid when sth has mysql_insertid' => sub {
    $db->fast_insert('mock_basic',{
        id   => 999,
        name => 'python',
    });

    my $guard = mock_guard('Teng' => {
        do_insert => { mysql_insertid => 999 },
    });

    my $row = $db->insert('mock_basic',{
        name => 'python',
    });

    isa_ok $row, 'HASH';
    is $row->{id}, 999;
    is $row->{name}, 'python';
};

done_testing;
