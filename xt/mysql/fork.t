use strict;
use warnings;
use utf8;
use xt::Utils::mysql;
use Test::More;
use Test::SharedFork;
use lib './t';
use Mock::BasicMySQL;

my $dbh = t::Utils->setup_dbh;
Mock::BasicMySQL->set_dbh($dbh);
Mock::BasicMySQL->setup_test_db;

# XXX: Correct operation is not done for set_dbh.
{
    Mock::BasicMySQL->txn_begin;
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1});

    if ( fork ) {
        wait;
        Mock::BasicMySQL->txn_rollback;
        ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1});
        Mock::BasicMySQL->cleanup_test_db;
        done_testing;
    }
    else {
        # child
        eval {
            Mock::BasicMySQL->insert('mock_basic_mysql',{
                name => 'perl',
            });
        };
        ok $@;
    }
    
}

