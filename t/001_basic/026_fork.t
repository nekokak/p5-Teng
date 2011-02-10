use t::Utils;
use Test::More;
use Mock::Basic;
use Test::SharedFork;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

    if (fork) {
        wait;
        my $row = $db->insert('mock_basic',{id => 1, name => 'perl'});
        is $row->id, 1;
        is $dbh, $db->dbh;

        done_testing;
    } else {
        eval { $db->dbh };
        ok $@;
        like $@, qr/this connection is no use\. because fork was done\./;
    }
 
