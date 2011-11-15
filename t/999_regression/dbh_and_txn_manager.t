use strict;
use Test::More;
use t::Utils;
use Mock::Basic;

subtest 'use transaction, disconnect, reconnect and use transaction again' => sub {
    my @connect_info = (
        'dbi:SQLite::memory:', 
        undef,
        undef,
        {RaiseError => 1, AutoCommit => 1},
    );
    my $model = Mock::Basic->new(connect_info => \@connect_info);

    eval {
        $model->txn_begin();
        $model->txn_rollback();
    };
    ok !$@, "regular txn begin, then rollback - should be clean" . ( $@ ? ", but got $@" : '');

    ok $model->{dbh}, "dbh should be defined";
    ok $model->{txn_manager}, "txn manager should be defined";

    eval {
        $model->disconnect();
    };
    ok !$@, "regular disconnect - should be clean" . ( $@ ? ", but got $@" : '');

    ok ! $model->{dbh}->ping, "dbh should be disconnected";
    if (! ok ! $model->{txn_manager}, "txn manager should be undefined" ) {
        # What, txn_manager still exists?!
        # Emulate this: long time passes... txn_manager and its dbh is
        # still dangling... and mysql server disconnects
        my $tm = $model->{txn_manager};
        if (my $dbh = $tm->{dbh}) {
            $dbh->disconnect;
        }
    }

    eval {
        $model->connect();
    };
    ok !$@, "regular connect - should be clean" . ( $@ ? ", but got $@" : '' );

    eval {
        $model->txn_begin();
        $model->txn_rollback();
    };
    ok !$@, "regular txn (again) - should be clean" . ($@ ? ", but got $@" : '');
};

subtest 'connect, use transaction, then connect' => sub {
    my @connect_info = (
        'dbi:SQLite::memory:', 
        undef,
        undef,
        {RaiseError => 1, AutoCommit => 1},
    );
    my $model = Mock::Basic->new(connect_info => \@connect_info);

    eval {
        $model->txn_begin();
        $model->txn_rollback();
    };
    ok !$@, "regular txn begin, then rollback - should be clean" . ( $@ ? ", but got $@" : '');

    my $old_dbh = $model->{dbh};
    my $old_tm  = $model->{txn_manager};

    ok $model->{dbh}, "dbh should be defined";
    ok $model->{txn_manager}, "txn manager should be defined";

    eval {
        $model->connect;
    };
    ok !$@, "slightly irregular, but reconnect using connect() again - should be clean" . ( $@ ? ", but got $@" : '');

    my $new_dbh = $model->{dbh};
    ok $new_dbh, "dbh should be defined";
    ok $new_dbh != $old_dbh, "...and is different from the previous one";
    if (! ok ! $model->{txn_manager}, "txn manager should be undefined" ) {
        # What, txn_manager still exists?!
        # Emulate this: long time passes... txn_manager and its dbh is
        # still dangling... and mysql server disconnects
        my $tm = $model->{txn_manager};
        if (my $dbh = $tm->{dbh}) {
            $dbh->disconnect;
        }
    }

    eval {
        $model->txn_begin();
        $model->txn_rollback();
    };
    ok !$@, "regular txn (again) - should be clean" . ($@ ? ", but got $@" : '');
};

done_testing;
