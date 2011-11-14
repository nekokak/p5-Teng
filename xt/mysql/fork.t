use strict;
use warnings;
use utf8;
use xt::Utils::mysql;
use Test::More;
use Test::SharedFork;
use lib './t';
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

# XXX: Correct operation is not done for set_dbh.
{
    $db->txn_begin;
    ok not +$db->single('mock_basic',{id => 1});

    if ( fork ) {
        wait;
        $db->txn_rollback;
        ok not +$db->single('mock_basic',{id => 1});
        done_testing;
    }
    else {
        # child
        eval {
            $db->insert('mock_basic',{
                name => 'perl',
            });
        };
        ok $@;
    }
    undef $db;
}

