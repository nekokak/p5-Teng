use t::Utils;
use Test::More;
use Mock::Basic;
use Test::Mock::Guard qw/mock_guard/;

unlink 'test.db';
my $dbh = t::Utils->setup_dbh('test.db');
my $db = Mock::Basic->new({dbh => $dbh, mode => 'ping'});
$db->setup_test_db;

subtest 'ping_reconnect' => sub {
    $db->reconnect;

    my $row;
    my $old_dbh = $db->dbh;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        $row = $db->insert('mock_basic',{
            name => 'perl',
        });
    };
    ok(!$@);

    isnt($old_dbh, $db->dbh);
    is_deeply($db->single('mock_basic', { id => $row->id })->get_columns, $row->get_columns);
};

subtest 'ping_reconnect_at_txn_begin' => sub {
    $db->reconnect;
    my $old_dbh = $db->dbh;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        $db->txn_begin;
    };
    ok(!$@);
    isnt($old_dbh, $db->dbh);

    my $row = $db->insert('mock_basic',{
        name => 'python',
    });
    $db->txn_commit;

    is_deeply($db->single('mock_basic', { id => $row->id })->get_columns, $row->get_columns);
};

subtest 'ping_reconnect_at_txn_scope' => sub {
    $db->reconnect;
    my $old_dbh = $db->dbh;
    my $scope;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        $scope = $db->txn_scope;
    };
    ok(!$@);
    isnt($old_dbh, $db->dbh);

    my $row = $db->insert('mock_basic',{
        name => 'ruby',
    });
    $scope->commit;

    is_deeply($db->single('mock_basic', { id => $row->id })->get_columns, $row->get_columns);
};

subtest 'ping_reconnect_at_after_txn_begin' => sub {
    $db->reconnect;
    $db->txn_begin;

    my $row;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        $row = $db->insert('mock_basic',{
            name => 'c++',
        });
    };
    like $@, qr/Detected transaction during a connect operation \(last known transaction at/;
    ok(!$row);

    $db->txn_rollback;
};

subtest 'ping_reconnect_at_after_txn_scope' => sub {
    $db->reconnect;
    my $scope = $db->txn_scope;

    my $row;
    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        $row = $db->insert('mock_basic',{
            name => 'golang',
        });
    };
    like $@, qr/Detected transaction during a connect operation \(last known transaction at/;
    ok(!$row);
    $scope->rollback;
};

subtest 'ping_reconnect_at_txn_commit' => sub {
    $db->reconnect;
    $db->txn_begin;

    my $row = $db->insert('mock_basic',{
        name => 'basic',
    });

    eval {
        my $guard; $guard = mock_guard('DBI::db' => +{ping => sub { undef $guard; return 0 } });
        $db->txn_commit;
    };
    like $@, qr/Detected transaction during a connect operation \(last known transaction at/;
    $db->txn_rollback;

    ok(!$db->single('mock_basic', { id => $row->id }));
};

subtest 'ping_reconnect_at_txn_scope_commit' => sub {
    $db->reconnect;
    my $row;
    {
        my $scope = $db->txn_scope;

        $row = $db->insert('mock_basic',{
            name => 'cobol',
        });

        eval {
            my $guard; $guard = mock_guard('DBIx::TransactionManager::ScopeGuard' => +{commit => sub { undef $guard; die('disconnect dbh') } });
            $scope->commit;
        };
        like $@, qr/disconnect dbh/;
        $scope->rollback;
    }

    ok(!$db->single('mock_basic', { id => $row->id }));
};

unlink 'test.db';
done_testing;
