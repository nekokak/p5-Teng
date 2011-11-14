use t::Utils;
use Test::More;
use Mock::Basic;
use Test::SharedFork;

unlink './t/main.db' if -f './t/main.db';
my $dbh = t::Utils->setup_dbh('./t/main.db');
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
Mock::Basic->load_plugin('AutoReconnect');

$db->disconnect;

    if (fork) {
        wait;
        $db->disconnect;
        my $row = $db->single('mock_basic',{id => 1});
        is $row->id, 1;
        is $row->name, 'perl';
        isnt $dbh, $db->dbh;

        unlink './t/main.db';

        done_testing;
    } else {
        my $row = $db->insert('mock_basic',{id => 1, name => 'perl'});
        is $row->id, 1;
    }
 
