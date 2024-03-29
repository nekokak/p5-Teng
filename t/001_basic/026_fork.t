use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Test::More;
use Mock::Basic;
use Test::SharedFork 0.15;

plan skip_all => 'not for Win32' if $^O eq 'MSWin32';

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
        my $dbh;
        eval { $dbh = $db->dbh };
        ok not $@;
        isa_ok $dbh, 'DBI::db';
    }

