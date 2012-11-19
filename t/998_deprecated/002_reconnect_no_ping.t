use t::Utils;
use Test::More;
use Mock::Basic;
use Test::Mock::Guard qw/mock_guard/;

unlink 'test.db';
my $dbh = t::Utils->setup_dbh('test.db');
my $db = Mock::Basic->new({dbh => $dbh, mode => 'no_ping'});
$db->setup_test_db;

subtest 'fixup_reconnect' => sub {
    $db->reconnect;
    my $row;
    my $old_dbh = $db->dbh;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        my $guard_execute; $guard_execute = mock_guard('DBI::st' => +{execute => sub {
            undef $guard_execute;
            die('disconnected');
        } });

        $row = $db->insert('mock_basic',{
            name => 'perl',
        });
    };
    like $@, qr/disconnected/;

    is($old_dbh, $db->dbh);
};

subtest 'fixup_reconnect_at_txn_begin' => sub {
    $db->reconnect;
    my $old_dbh = $db->dbh;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        my $guard_begin; $guard_begin = mock_guard('DBI::db' => +{begin_work => sub {
            undef $guard_begin;
            die('disconnected');
        } });
        $db->txn_begin;
    };
    like $@, qr/disconnected/;
    is($old_dbh, $db->dbh);
};

subtest 'fixup_reconnect_at_txn_scope' => sub {
    $db->reconnect;
    my $old_dbh = $db->dbh;
    my $scope;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        my $guard_begin; $guard_begin = mock_guard('DBI::db' => +{begin_work => sub {
            undef $guard_begin;
            die('disconnected');
        } });
        $scope = $db->txn_scope;
    };
    like $@, qr/disconnected/;
    is($old_dbh, $db->dbh);
};

subtest 'fixup_reconnect_at_after_txn_begin' => sub {
    $db->reconnect;
    $db->txn_begin;

    my $row;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        my $guard_execute; $guard_execute = mock_guard('DBI::st' => +{execute => sub {
            undef $guard_execute;
            die('disconnected');
        } });
        $row = $db->insert('mock_basic',{
            name => 'c++',
        });
    };
    like $@, qr/disconnected/;
    $db->txn_rollback;
};

subtest 'fixup_reconnect_at_after_txn_scope' => sub {
    $db->reconnect;
    my $scope = $db->txn_scope;

    my $row;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        my $guard_execute; $guard_execute = mock_guard('DBI::st' => +{execute => sub {
            undef $guard_execute;
            die('disconnected');
        } });
        $row = $db->insert('mock_basic',{
            name => 'golang',
        });
    };
    like $@, qr/disconnected/;
    $scope->rollback;
};

subtest 'fixup_reconnect_at_txn_commit' => sub {
    $db->reconnect;
    $db->txn_begin;

    my $row = $db->insert('mock_basic',{
        name => 'basic',
    });

    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        my $guard_commit; $guard_commit = mock_guard('DBI::db' => +{commit => sub {
            undef $guard_commit;
            die('disconnected');
        } });
        $db->txn_commit;
    };
    like $@, qr/disconnected/;
};

subtest 'fixup_reconnect_at_txn_scope_commit' => sub {
    $db->reconnect;
    my $row;
    {
        my $scope = $db->txn_scope;

        $row = $db->insert('mock_basic',{
            name => 'cobol',
        });

        eval {
            my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
            my $guard_commit; $guard_commit = mock_guard('DBIx::TransactionManager::ScopeGuard' => +{commit => sub {
                undef $guard_commit;
                die('disconnected');
            }});
            $scope->commit;
        };
        like $@, qr/disconnected/;
        $scope->rollback;
    }
};


unlink 'test.db';
done_testing;
