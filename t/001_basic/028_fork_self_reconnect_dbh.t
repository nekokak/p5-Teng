use t::Utils;
use Test::More;
use Mock::Basic;
use Test::SharedFork;

my $dbh = t::Utils->setup_dbh('./t/main.db');
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

    if (fork) {
        wait;
        my $row = $db->single('mock_basic',{id => 1});
        is $row->id, 1;
        is $row->name, 'perl';
        is $dbh, $db->dbh;

        unlink './t/main.db';

        done_testing;
    } else {
        $db->reconnect;
        my $row = $db->insert('mock_basic',{id => 1, name => 'perl'});
        is $row->id, 1;
    }
 
