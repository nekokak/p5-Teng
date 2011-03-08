package Teng::Connector;
use Carp::Always;
use strict;
use Class::Accessor::Lite 
    rw => [ qw(
        owner
        connect_info
        driver_name
        on_connect_do
        on_disconnect_do
        sql_builder
        txn_manager
    ) ]
;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    if ($args{dbh}) {
        return $class->new_from_dbh( %args );
    }

    my $self = $class->_new( %args );
    $self->_setup_driver( (split /:/, $self->connect_info->[0])[1]);
    $self->_dbh; # connect now!

    $self;
}

sub DESTROY {
    $_[0]->disconnect if $_[0]->{_dond};
}

sub _new {
    my $class = shift;
    return bless {
        @_,
        _dbh       => undef,
        _dond      => 1,
        _svp_depth => 0,
    } => $class;
}

sub new_from_dbh {
    my ($class, %args) = @_;
    my $dbh = delete $args{dbh};
    my $self = $class->_new(%args);
    $self->_set_dbh($dbh);
    $self->_setup_driver( $dbh->{Driver}->{Name});
    return $self;
}


sub _setup_driver {
    my ($self, $driver_name) = @_;
    $self->driver_name($driver_name);
    my $builder = $self->sql_builder;
    if (! $builder ) {
        # XXX Hackish
        $builder = Teng::QueryBuilder->new(driver => $driver_name);
        $self->sql_builder( $builder );
    }
}

# should be called on init/connect/reconnect
sub _set_dbh {
    my ($self, $dbh) = @_;
    
    $dbh->STORE(AutoInactiveDestroy => 1)
        if DBI->VERSION > 1.613 && !$dbh->FETCH('AutoInactiveDestroy');

    $self->{_pid} = $$;
    $self->{_tid} = threads->tid if $INC{'threads.pm'};
    $self->{_dbh} = $dbh;
    $self->txn_manager( DBIx::TransactionManager->new($dbh) );
}

sub connect {
    my $self = ref $_[0] ? shift : shift->new(@_);
    $self->{_dond} = 0;
    $self->dbh;
}

sub dbh {
    my $self = shift;
    my $dbh = $self->_seems_connected or return $self->_connect;
    my $ret = $self->connected ? $dbh : $self->_connect;
    if (! $ret) {
        $self->_run_on_disconnect;
    }
    return $ret;
}

# Just like dbh(), except it doesn't ping the server.
sub _dbh {
    my $self = shift;
    $self->_seems_connected || $self->_connect;
}

sub reconnect {
    my $self = shift;

    if ($self->connector->in_transaction) {
        Carp::confess("Detected disconnected database during a transaction. Refusing to proceed");
    }

    $self->disconnect();
    $self->connect(@_);
}
sub connected {
    my $self = shift;
    return unless $self->_seems_connected;
    my $dbh = $self->{_dbh} or return;
    return $dbh->ping();
}

sub _connect {
    my $self = shift;

    my $connect_info = $self->connect_info;
    if (! $connect_info && ! $self->{_dbh}) {
        die "PANIC: no connect_info, and no _dbh";
    }

    return unless $connect_info;

    my $options = $connect_info->[3] ||= {};
    my %default = (
        AutoCommit => 1,
        PrintError => 0,
        RaiseError => 1,
    );
    while (my ($k, $v) = each %default) {
        if (! exists $options->{$k}) {
            $options->{$k} = $v;
        }
    }

    if (my $tm = $self->txn_manager) {
        if ( my $info = $tm->in_transaction ) {
            my $caller = $info->{caller};
            my $pid    = $info->{pid};
            Carp::confess("Detected transaction during a connect operation (last known transaction at $caller->[1] line $caller->[2], pid $pid). Refusing to proceed at");
        }
    }

    my $dbh = do {
        if ($INC{'Apache/DBI.pm'} && $ENV{MOD_PERL}) {
            local $DBI::connect_via = 'connect'; # Disable Apache::DBI.
            DBI->connect( @$connect_info );
        } else {
            DBI->connect( @$connect_info );
        }
    };

    if (! $dbh) {
        # XXX - cleanup?
        return ();
    }
    $self->_set_dbh( $dbh );
    $self->_run_on_connect();

    return $dbh;
}

sub _run_on_connect {
    my $self = shift;
    if ( my $on_connect_do = $self->on_connect_do ) {
        my $teng = $self->owner;
        if (not ref($on_connect_do)) {
            $teng->do($on_connect_do);
        } elsif (ref($on_connect_do) eq 'CODE') {
            $on_connect_do->($teng);
        } elsif (ref($on_connect_do) eq 'ARRAY') {
            $teng->do($_) for @$on_connect_do;
        } else {
            Carp::croak('Invalid on_connect_do: '.ref($on_connect_do));
        }
    }
}

sub _run_on_disconnect {
    my $self = shift;
    if (my $on_disconnect_do = $self->on_disconnect_do ) {
        my $teng = $self->owner;
        $on_disconnect_do->($teng);
    }
    $self->txn_manager( undef );
}


sub _seems_connected {
    my $self = shift;
    my $dbh = $self->{_dbh} or return;
    if ( defined $self->{_tid} && $self->{_tid} != threads->tid ) {
        return;
    } elsif ( $self->{_pid} != $$ ) {
        # We've forked, so prevent the parent process handle from touching the
        # DB on DESTROY. Here in the child process, that could really screw
        # things up. This is superfluous when AutoInactiveDestroy is set, but
        # harmless. It's better to be proactive anyway.
        $dbh->STORE(InactiveDestroy => 1);
        return;
    }
    # Use FETCH() to avoid death when called from during global destruction.
    return $dbh->FETCH('Active') ? $dbh : undef;
}

sub disconnect {
    my $self = shift;
    if (my $dbh = $self->{_dbh}) {
        # Some databases need this to stop spewing warnings, according to
        # DBIx::Class::Storage::DBI.
        $dbh->STORE(CachedKids => {});
        no warnings 'numeric';
        if ( $self->driver_name =~ /SQLite/i &&$DBD::SQLite::VERSION >= 1.32 ) {
            $dbh->disconnect;
        }
        $self->{_dbh} = undef;
        $self->_run_on_disconnect;
    }
    return $self;
}

1;