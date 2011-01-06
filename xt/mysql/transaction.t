use t::Utils;
use xt::Utils::mysql;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'do basic transaction' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 1;
    is $row->name, 'perl';
    Mock::Basic->txn_commit;
    
    is +Mock::Basic->single('mock_basic',{id => 1})->name, 'perl';
    done_testing;
};
 
subtest 'do rollback' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    Mock::Basic->txn_rollback;
    
    ok not +Mock::Basic->single('mock_basic',{id => 2});
    done_testing;
};

subtest 'do commit' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 3;
    is $row->name, 'perl';
    Mock::Basic->txn_commit;
 
    ok +Mock::Basic->single('mock_basic',{id => 3});
    done_testing;
};
 
subtest 'do scope commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 4;
    is $row->name, 'perl';
    $txn->commit;
 
    ok +Mock::Basic->single('mock_basic',{id => 4});
    done_testing;
};
 
subtest 'do scope rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 5;
    is $row->name, 'perl';
    $txn->rollback;
 
    ok not +Mock::Basic->single('mock_basic',{id => 5});
    done_testing;
};
 
subtest 'do scope guard for rollback' => sub {
 
    {
        local $SIG{__WARN__} = sub {};
        my $txn = Mock::Basic->txn_scope;
        my $row = Mock::Basic->insert('mock_basic',{
            name => 'perl',
        });
        is $row->id, 6;
        is $row->name, 'perl';
    }
 
    ok not +Mock::Basic->single('mock_basic',{id => 6});
    done_testing;
};

subtest 'do nested scope rollback-rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 7;
        is $row2->name, 'perl5.10';
        $txn2->rollback;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 8;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 7});
    ok not +Mock::Basic->single('mock_basic',{id => 8});
    done_testing;
};

subtest 'do nested scope commit-rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 9;
        is $row2->name, 'perl5.10';
        $txn2->commit;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 10;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 9});
    ok not +Mock::Basic->single('mock_basic',{id => 10});
    done_testing;
};

subtest 'do nested scope rollback-commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 11;
        is $row2->name, 'perl5.10';
        $txn2->rollback;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 12;
    is $row->name, 'perl5.12';

    eval { $txn->commit };

    like( $@, qr/tried to commit but already rollbacked in nested transaction./, "error message" );

    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 11});
    ok not +Mock::Basic->single('mock_basic',{id => 12});
    done_testing;
};

subtest 'do nested scope commit-commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 13;
        is $row2->name, 'perl5.10';
        $txn2->commit;
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 14;
    is $row->name, 'perl5.12';
    $txn->commit;

    ok +Mock::Basic->single('mock_basic',{id => 13});
    ok +Mock::Basic->single('mock_basic',{id => 14});
    done_testing;
};

subtest 'do nested scope rollback-commit-rollback' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        local $SIG{__WARN__} = sub {};
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 15;
        is $row2->name, 'perl5.10';

        {
            my $txn3 = Mock::Basic->txn_scope;
            my $row3 = Mock::Basic->insert('mock_basic',{
                name => 'perl',
            });
            is $row3->id, 16;
            is $row3->name, 'perl';
        }

        eval { $txn2->commit };
        like( $@, qr/tried to commit but already rollbacked in nested transaction./, "error message" );
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 17;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 15});
    ok not +Mock::Basic->single('mock_basic',{id => 16});
    ok not +Mock::Basic->single('mock_basic',{id => 17});
    done_testing;
};

subtest 'do nested scope rollback-commit-commit' => sub {
    my $txn = Mock::Basic->txn_scope;
    {
        local $SIG{__WARN__} = sub {};
        my $txn2 = Mock::Basic->txn_scope;
        my $row2 = Mock::Basic->insert('mock_basic',{
            name => 'perl5.10',
        });
        is $row2->id, 18;
        is $row2->name, 'perl5.10';

        {
            my $txn3 = Mock::Basic->txn_scope;
            my $row3 = Mock::Basic->insert('mock_basic',{
                name => 'perl',
            });
            is $row3->id, 19;
            is $row3->name, 'perl';
        }
    }
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl5.12',
    });
    is $row->id, 20;
    is $row->name, 'perl5.12';

    eval { $txn->commit };
    like( $@, qr/tried to commit but already rollbacked in nested transaction./, "error message" );
    $txn->rollback;

    ok not +Mock::Basic->single('mock_basic',{id => 18});
    ok not +Mock::Basic->single('mock_basic',{id => 19});
    ok not +Mock::Basic->single('mock_basic',{id => 20});
    done_testing;
};

done_testing;


