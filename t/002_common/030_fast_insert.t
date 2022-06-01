use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::Mock::Guard qw/mock_guard/;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
my $db_with_strict_sql_builder = Mock::Basic->new({dbh => $dbh, sql_builder_args => { strict => 1 }});
$db->setup_test_db;

subtest 'fast_insert returning last_insert_id' => sub {
    my $id = $db->fast_insert('mock_basic',{
        name => 'perl',
    });
    is $id, 1;

    my $id2 = $db->fast_insert('mock_basic',{
        name => 'ruby',
    });
    is $id2, 2;
};

subtest 'fast_insert returning mysql_insertid when sth has mysql_insertid' => sub {
    my $guard = mock_guard('Teng' => {
        do_insert => { mysql_insertid => 3 },
    });

    my $id = $db->fast_insert('mock_basic',{
        name => 'ruby',
    });
    is $id, 3;
};

done_testing;
