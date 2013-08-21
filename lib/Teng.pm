package Teng;
use strict;
use warnings;
use Carp ();
use Class::Load ();
use DBI 1.33;
use Teng::Row;
use Teng::Iterator;
use Teng::Schema;
use DBIx::TransactionManager 1.06;
use Teng::QueryBuilder;
use Class::Accessor::Lite
   rw => [ qw(
        connect_info
        on_connect_do
        schema
        schema_class
        suppress_row_objects
        sql_builder
        sql_comment
        owner_pid
        no_ping
        fields_case
    )]
;

our $VERSION = '0.20';

sub load_plugin {
    my ($class, $pkg, $opt) = @_;
    $pkg = $pkg =~ s/^\+// ? $pkg : "Teng::Plugin::$pkg";
    Class::Load::load_class($pkg);

    $class = ref($class) if ref($class);

    my $alias = delete $opt->{alias} || +{};
    {
        no strict 'refs';
        for my $method ( @{"${pkg}::EXPORT"} ){
            *{$class . '::' . ($alias->{$method} || $method)} = $pkg->can($method);
        }
    }

    $pkg->init($class, $opt) if $pkg->can('init');
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $loader = delete $args{loader};

    if ( my $mode = delete $args{mode} ) {
        warn "IMPORTANT: 'mode' option is DEPRECATED AND *WILL* BE REMOVED. PLEASE USE 'no_ping' option.\n";
        if ( !exists $args{no_ping} ) {
            $args{no_ping} = $mode eq 'ping' ? 0 : 1; 
        }
    }

    my $self = bless {
        schema_class => "$class\::Schema",
        owner_pid    => $$,
        no_ping      => 0,
        fields_case  => 'NAME_lc',
        %args,
    }, $class;

    if (!$loader && ! $self->schema) {
        my $schema_class = $self->{schema_class};
        Class::Load::load_class( $schema_class );
        my $schema = $schema_class->instance;
        if (! $schema) {
            Carp::croak("schema object was not passed, and could not get schema instance from $schema_class");
        }
        $schema->namespace($class);
        $self->schema( $schema );
    }

    unless ($self->connect_info || $self->{dbh}) {
        Carp::croak("'dbh' or 'connect_info' is required.");
    }

    if ( ! $self->{dbh} ) {
        $self->connect;
    } else {
        $self->_prepare_from_dbh;
    }

    return $self;
}

sub mode {
    my $self = shift;
    warn "IMPORTANT: 'mode' option is DEPRECATED AND *WILL* BE REMOVED. PLEASE USE 'no_ping' option.\n";

    if ( @_ ) {
        my $mode = shift;
        if ( $mode eq 'ping' ) {
            $self->no_ping(0);
        }
        else {
            $self->no_ping(1);
        }
    }

    return $self->no_ping ? 'no_ping' : 'ping';
}

# forcefully connect
sub connect {
    my ($self, @args) = @_;

    $self->in_transaction_check;

    if (@args) {
        $self->connect_info( \@args );
    }
    my $connect_info = $self->connect_info;
    $connect_info->[3] = {
        # basic defaults
        AutoCommit => 1,
        PrintError => 0,
        RaiseError => 1,
        %{ $connect_info->[3] || {} },
    };

    $self->{dbh} = eval { DBI->connect(@$connect_info) }
        or Carp::croak("Connection error: " . ($@ || $DBI::errstr));
    delete $self->{txn_manager};

    $self->owner_pid($$);

    $self->_on_connect_do;
    $self->_prepare_from_dbh;
}

sub _on_connect_do {
    my $self = shift;

    if ( my $on_connect_do = $self->on_connect_do ) {
        if (not ref($on_connect_do)) {
            $self->do($on_connect_do);
        } elsif (ref($on_connect_do) eq 'CODE') {
            $on_connect_do->($self);
        } elsif (ref($on_connect_do) eq 'ARRAY') {
            $self->do($_) for @$on_connect_do;
        } else {
            Carp::croak('Invalid on_connect_do: '.ref($on_connect_do));
        }
    }
}

sub reconnect {
    my $self = shift;

    $self->in_transaction_check;

    my $dbh = $self->{dbh};

    $self->disconnect();

    if ( @_ ) {
        $self->connect(@_);
    }
    else {
        # Why don't use $dbh->clone({InactiveDestroy => 0}) ?
        # because, DBI v1.616 clone with \%attr has bug.
        # my $dbh2 = $dbh->clone({});
        # my $dbh3 = $dbh2->clone({});
        # $dbh2 is ok, but $dbh3 is undef.
        # ---
        # Don't assign $self-{dbh} directry.
        # Because if $self->{dbh} is undef then reconnect fail always.
        # https://github.com/nekokak/p5-Teng/pull/98
        my $new_dbh = eval { $dbh->clone }
            or Carp::croak("ReConnection error: " . ($@ || $DBI::errstr));
        $self->{dbh} = $new_dbh;
        $self->{dbh}->{InactiveDestroy} = 0;

        $self->owner_pid($$);
        $self->_on_connect_do;
        $self->_prepare_from_dbh;
    }
}

sub disconnect {
    my $self = shift;

    delete $self->{txn_manager};
    if ( my $dbh = $self->{dbh} ) {
        if ( $self->owner_pid && ($self->owner_pid != $$) ) {
            $dbh->{InactiveDestroy} = 1;
        }
        else {
            $dbh->disconnect;
        }
    }
    $self->owner_pid(undef);
}

sub _prepare_from_dbh {
    my $self = shift;

    $self->{driver_name} = $self->{dbh}->{Driver}->{Name};
    my $builder = $self->{sql_builder};
    if (! $builder ) {
        # XXX Hackish
        $builder = Teng::QueryBuilder->new(driver => $self->{driver_name} );
        $self->sql_builder( $builder );
    }
    $self->{dbh}->{FetchHashKeyName} = $self->{fields_case};

    $self->{schema}->prepare_from_dbh($self->{dbh}) if $self->{schema};
}

sub _verify_pid {
    my $self = shift;

    if ( !$self->owner_pid || $self->owner_pid != $$ ) {
        $self->reconnect;
    }
    elsif ( my $dbh = $self->{dbh} ) {
        if ( !$dbh->FETCH('Active') ) {
            $self->reconnect;
        }
        elsif ( !$self->no_ping && !$dbh->ping) {
            $self->reconnect;
        }
    }
}

sub dbh {
    my $self = shift;

    $self->_verify_pid;
    $self->{dbh};
}

sub connected {
    my $self = shift;
    my $dbh = $self->{dbh};
    return $self->owner_pid && $dbh->ping;
}

sub _execute {
    my $self = shift;
    warn "IMPORTANT: '_execute' method is DEPRECATED AND *WILL* BE REMOVED. PLEASE USE 'execute' method.\n";
    return $self->execute(@_);
}

our $SQL_COMMENT_LEVEL = 0;
sub execute {
    my ($self, $sql, $binds) = @_;

    if ($ENV{TENG_SQL_COMMENT} || $self->sql_comment) {
        my $i = $SQL_COMMENT_LEVEL; # optimize, as we would *NEVER* be called
        while ( my (@caller) = caller($i++) ) {
            next if ( $caller[0]->isa( __PACKAGE__ ) );
            my $comment = "$caller[1] at line $caller[2]";
            $comment =~ s/\*\// /g;
            $sql = "/* $comment */\n$sql";
            last;
        }
    }

    my $sth;
    eval {
        $sth = $self->dbh->prepare($sql);
        my $i = 1;
        for my $v ( @{ $binds || [] } ) {
            $sth->bind_param( $i++, ref($v) eq 'ARRAY' ? @$v : $v );
        }
        $sth->execute();
    };

    if ($@) {
        $self->handle_error($sql, $binds, $@);
    }

    return $sth;
}

sub _last_insert_id {
    my ($self, $table_name) = @_;

    my $driver = $self->{driver_name};
    if ( $driver eq 'mysql' ) {
        return $self->dbh->{mysql_insertid};
    } elsif ( $driver eq 'Pg' ) {
        return $self->dbh->last_insert_id( undef, undef, undef, undef,{ sequence => join( '_', $table_name, 'id', 'seq' ) } );
    } elsif ( $driver eq 'SQLite' ) {
        return $self->dbh->func('last_insert_rowid');
    } elsif ( $driver eq 'Oracle' ) {
        return;
    } else {
        Carp::croak "Don't know how to get last insert id for $driver";
    }
}

sub _bind_sql_type_to_args {
    my ( $self, $table, $args ) = @_;
    my $bind_args = {};

    for my $col (keys %{$args}) {
        # if $args->{$col} is a ref, it is scalar ref or already
        # sql type bined parameter. so ignored.
        $bind_args->{$col} = ref $args->{$col} ? $args->{$col} : [ $args->{$col}, $table->get_sql_type($col) ];
    }

    return $bind_args;
}

sub do_insert {
    my ($self, $table_name, $args, $prefix) = @_;

    $prefix ||= 'INSERT INTO';
    my $table = $self->schema->get_table($table_name);
    if (! $table) {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        Carp::croak( "Table definition for $table_name does not exist (Did you declare it in our schema?)" );
    }

    for my $col (keys %{$args}) {
        $args->{$col} = $table->call_deflate($col, $args->{$col});
    }
    my $bind_args = $self->_bind_sql_type_to_args( $table, $args );
    my ($sql, @binds) = $self->{sql_builder}->insert( $table_name, $bind_args, { prefix => $prefix } );
    $self->execute($sql, \@binds);
}

sub fast_insert {
    my ($self, $table_name, $args, $prefix) = @_;

    $self->do_insert($table_name, $args, $prefix);
    $self->_last_insert_id($table_name);
}

sub insert {
    my ($self, $table_name, $args, $prefix) = @_;

    $self->do_insert($table_name, $args, $prefix);

    my $table = $self->schema->get_table($table_name);
    my $pk = $table->primary_keys();
    if (scalar(@$pk) == 1 && not defined $args->{$pk->[0]}) {
        $args->{$pk->[0]} = $self->_last_insert_id($table_name);
    }

    return $args if $self->suppress_row_objects;

    if (scalar(@$pk) == 1) {
        return $self->single($table_name, {$pk->[0] => $args->{$pk->[0]}});
    }

    $table->row_class->new(
        {
            row_data   => $args,
            teng       => $self,
            table_name => $table_name,
        }
    );
}

sub bulk_insert {
    my ($self, $table_name, $args) = @_;

    return unless scalar(@{$args||[]});

    my $dbh = $self->dbh;
    my $can_multi_insert = $dbh->{Driver}->{Name} eq 'mysql' ? 1
                         : $dbh->{Driver}->{Name} eq 'Pg'
                             && $dbh->{ pg_server_version } >= 82000 ? 1
                         : 0;

    if ($can_multi_insert) {
        my $table = $self->schema->get_table($table_name);
        if (! $table) {
            Carp::croak( "Table definition for $table_name does not exist (Did you declare it in our schema?)" );
        }

        if ( $table->has_deflators ) {
            for my $row (@$args) {
                for my $col (keys %{$row}) {
                    $row->{$col} = $table->call_deflate($col, $row->{$col});
                }
            }
        }

        my ($sql, @binds) = $self->sql_builder->insert_multi( $table_name, $args );
        $self->execute($sql, \@binds);
    } else {
        # use transaction for better performance and atomicity.
        my $txn = $self->txn_scope();
        for my $arg (@$args) {
            # do not run trigger for consistency with mysql.
            $self->insert($table_name, $arg);
        }
        $txn->commit;
    }
}

sub do_update {
    my ($self, $table_name, $args, $where) = @_;

    my ($sql, @binds) = $self->{sql_builder}->update( $table_name, $args, $where );
    my $sth = $self->execute($sql, \@binds);
    my $rows = $sth->rows;
    $sth->finish;

    $rows;
}

sub update {
    my ($self, $table_name, $args, $where) = @_;

    my $table = $self->schema->get_table($table_name);
    if (! $table) {
        Carp::croak( "Table definition for $table_name does not exist (Did you declare it in our schema?)" );
    }

    for my $col (keys %{$args}) {
       $args->{$col} = $table->call_deflate($col, $args->{$col});
    }
    
    $self->do_update($table_name, $self->_bind_sql_type_to_args( $table, $args ), $where);
}

sub delete {
    my ($self, $table_name, $where) = @_;

    my ($sql, @binds) = $self->{sql_builder}->delete( $table_name, $where );
    my $sth = $self->execute($sql, \@binds);
    my $rows = $sth->rows;
    $sth->finish;

    $rows;
}

#--------------------------------------------------------------------------------
# for transaction
sub txn_manager  {
    my $self = shift;
    $self->_verify_pid;
    $self->{txn_manager} ||= DBIx::TransactionManager->new($self->dbh);
}

sub in_transaction_check {
    my $self = shift;

    return unless $self->{txn_manager};

    if ( my $info = $self->{txn_manager}->in_transaction ) {
        my $caller = $info->{caller};
        my $pid    = $info->{pid};
        Carp::confess("Detected transaction during a connect operation (last known transaction at $caller->[1] line $caller->[2], pid $pid). Refusing to proceed at");
    }
}

sub txn_scope {
    my $self = shift;
    my @caller = caller();

    $self->txn_manager->txn_scope(caller => \@caller);
}

sub txn_begin {
    my $self = shift;

    $self->txn_manager->txn_begin;
}
sub txn_rollback { $_[0]->txn_manager->txn_rollback }
sub txn_commit   { $_[0]->txn_manager->txn_commit   }
sub txn_end      { $_[0]->txn_manager->txn_end      }

#--------------------------------------------------------------------------------

sub do {
    my ($self, $sql, $attr, @bind_vars) = @_;
    my $ret;
    eval { $ret = $self->dbh->do($sql, $attr, @bind_vars) };
    if ($@) {
        $self->handle_error($sql, @bind_vars ? \@bind_vars : '', $@);
    }
    $ret;
}

sub _get_select_columns {
    my ($self, $table, $opt) = @_;

    return $opt->{'+columns'}
        ? [@{$table->{escaped_columns}{$self->{driver_name}}}, @{$opt->{'+columns'}}]
        : ($opt->{columns} || $table->{escaped_columns}{$self->{driver_name}})
    ;
}

sub search {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->{schema}->get_table( $table_name );
    if (! $table) {
        Carp::croak("No such table $table_name");
    }

    my ($sql, @binds) = $self->{sql_builder}->select(
        $table_name,
        $self->_get_select_columns($table, $opt),
        $where,
        $opt
    );

    $self->search_by_sql($sql, \@binds, $table_name);
}

sub _bind_named {
    my ($self, $sql, $args ) = @_;

    my @bind;
    $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
        Carp::croak("'$1' does not exist in bind hash") if !exists $args->{$1};
        if ( ref $args->{$1} && ref $args->{$1} eq "ARRAY" ) {
            push @bind, @{ $args->{$1} };
            my $tmp = join ',', map { '?' } @{ $args->{$1} };
            "( $tmp )";
        } else {
            push @bind, $args->{$1};
            '?'
        }
    }ge;

    return ($sql, \@bind);
}

sub search_named {
    my ($self, $sql, $args, $table_name) = @_;

    $self->search_by_sql($self->_bind_named($sql, $args), $table_name);
}

sub single {
    my ($self, $table_name, $where, $opt) = @_;

    $opt->{limit} = 1;

    my $table = $self->{schema}->get_table( $table_name );
    Carp::croak("No such table $table_name") unless $table;

    my ($sql, @binds) = $self->{sql_builder}->select(
        $table_name,
        $self->_get_select_columns($table, $opt),
        $where,
        $opt
    );
    my $sth = $self->execute($sql, \@binds);
    my $row = $sth->fetchrow_hashref($self->{fields_case});

    return undef unless $row; ## no critic
    return $row if $self->{suppress_row_objects};

    $table->{row_class}->new(
        {
            sql        => $sql,
            row_data   => $row,
            teng       => $self,
            table      => $table,
            table_name => $table_name,
        }
    );
}

sub search_by_sql {
    my ($self, $sql, $bind, $table_name) = @_;

    $table_name ||= $self->_guess_table_name( $sql );
    my $sth = $self->execute($sql, $bind);
    my $itr = Teng::Iterator->new(
        teng             => $self,
        sth              => $sth,
        sql              => $sql,
        row_class        => $self->{schema}->get_row_class($table_name),
        table            => $self->{schema}->get_table( $table_name ),
        table_name       => $table_name,
        suppress_object_creation => $self->{suppress_row_objects},
    );
    return wantarray ? $itr->all : $itr;
}

sub single_by_sql {
    my ($self, $sql, $bind, $table_name) = @_;

    $table_name ||= $self->_guess_table_name( $sql );
    my $table = $self->{schema}->get_table( $table_name );
    Carp::croak("No such table $table_name") unless $table;

    my $sth = $self->execute($sql, $bind);
    my $row = $sth->fetchrow_hashref($self->{fields_case});

    return unless $row;
    return $row if $self->{suppress_row_objects};

    $table->{row_class}->new(
        {
            sql        => $sql,
            row_data   => $row,
            teng       => $self,
            table      => $table,
            table_name => $table_name,
        }
    );
}

sub single_named {
    my ($self, $sql, $args, $table_name) = @_;

    $self->single_by_sql($self->_bind_named($sql, $args), $table_name);
}

sub _guess_table_name {
    my ($class, $sql) = @_;

    if ($sql =~ /\sfrom\s+["`]?([\w]+)["`]?\s*/si) {
        return $1;
    }
    return;
}

sub handle_error {
    my ($self, $stmt, $bind, $reason) = @_;
    require Data::Dumper;

    local $Data::Dumper::Maxdepth = 2;
    $stmt =~ s/\n/\n          /gm;
    Carp::croak sprintf <<"TRACE", $reason, $stmt, Data::Dumper::Dumper($bind);
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ Teng 's Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
}

sub DESTROY {
    my $self = shift;

    if ( $self->owner_pid and $self->owner_pid != $$ and my $dbh = $self->{dbh} ) {
        $dbh->{InactiveDestroy} = 1;
    }
}

1;

__END__
=head1 NAME

Teng - very simple DBI wrapper/ORMapper

=head1 SYNOPSIS

    my $db = MyDB->new({ connect_info => [ 'dbi:SQLite:' ] });
    my $row = $db->insert( 'table' => {
        col1 => $value
    } );

=head1 DESCRIPTION

Teng is very simple DBI wrapper and simple O/R Mapper.
It aims to be lightweight, with minimal dependencies so it's easier to install. 

=head1 BASIC USAGE

create your db model base class.

    package Your::Model;
    use parent 'Teng';
    1;
    
create your db schema class.
See Teng::Schema for docs on defining schema class.

    package Your::Model::Schema;
    use Teng::Schema::Declare;
    table {
        name 'user';
        pk 'id';
        columns qw( foo bar baz );
    };
    1;
    
in your script.

    use Your::Model;
    
    my $teng = Your::Model->new(\%args);
    # insert new record.
    my $row = $teng->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'}); # same do { $row->name('nekokak'); $row->update; }

    $row = $teng->single_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete();

=head1 ARCHITECTURE

Teng classes are comprised of three distinct components:

=head2 MODEL

The C<model> is where you say 

    package MyApp::Model;
    use parent 'Teng';

This is the entry point to using Teng. You connect, insert, update, delete, select stuff using this object.

=head2 SCHEMA

The C<schema> is a simple class that describes your table definitions. Note that this is different from DBIx::Class terms.
DBIC's schema is equivalent to Teng's model + schema, where the actual schema information is scattered across the result classes.

In Teng, you simply use Teng::Schema's domain specific language to define a set of tables

    package MyApp::Model::Schema;
    use Teng::Schema::Declare;

    table {
        name $table_name;
        pk $primary_key_column;
        columns qw(
            column1
            column2
            column3
        );
    }

    ... and other tables ...

=head2 ROW

Unlike DBIx::Class, you don't need to have a set of classes that represent a row type (i.e. "result" classes in DBIC terms).
In Teng, the row objects are blessed into anonymous classes that inherit from Teng::Row,
so you don't have to create these classes if you just want to use some simple queries.

If you want to define methods to be performed by your row objects, simply create a row class like so:

    package MyApp::Model::Row::Camelizedtable_name;
    use parent qw(Teng::Row);

Note that your table name will be camelized.

=head1 METHODS

Teng provides a number of methods to all your classes, 

=over

=item $teng = Teng->new(\%args)

Creates a new Teng instance.

    # connect new database connection.
    my $db = Your::Model->new(
        connect_info => [ $dsn, $username, $password, \%connect_options ]
    );

Arguments can be:

=over

=item * C<connect_info>

Specifies the information required to connect to the database.
The argument should be a reference to a array in the form:

    [ $dsn, $user, $password, \%options ]

You must pass C<connect_info> or C<dbh> to the constructor.

=item * C<dbh>

Specifies the database handle to use. 

=item * C<no_ping>

By default, ping before each executing query.
If it affect performance then you can set to true for ping stopping.

=item * C<fields_case>

specific DBI.pm's FetchHashKeyName.

=item * C<schema>

Specifies the Teng::Schema instance to use.
If not specified, the value specified in C<schema_class> is loaded and 
instantiated for you.

=item * C<schema_class>

Specifies the schema class to use.
By default {YOUR_MODEL_CLASS}::Schema is used.

=item * C<suppress_row_objects>

Specifies the row object creation mode. By default this value is C<false>.
If you specifies this to a C<true> value, no row object will be created when
a C<SELECT> statement is issued..

=item * C<sql_builder>

Speficies the SQL builder object. By default SQL::Maker is used, and as such,
if you provide your own SQL builder the interface needs to be compatible
with SQL::Maker.

=back

=item C<$row = $teng-E<gt>insert($table_name, \%row_data)>

Inserts a new record. Returns the inserted row object.

    my $row = $teng->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

If a primary key is available, it will be fetched after the insert -- so
an INSERT followed by SELECT is performed. If you do not want this, use
C<fast_insert>.

=item C<$last_insert_id = $teng-E<gt>fast_insert($table_name, \%row_data);>

insert new record and get last_insert_id.

no creation row object.

=item C<$teng-E<gt>bulk_insert($table_name, \@rows_data)>

Accepts either an arrayref of hashrefs.
each hashref should be a structure suitable
for submitting to a Your::Model->insert(...) method.
The second argument is an arrayref of hashrefs. All of the keys in these hashrefs must be exactly the same.

insert many record by bulk.

example:

    Your::Model->bulk_insert('user',[
        {
            id   => 1,
            name => 'nekokak',
        },
        {
            id   => 2,
            name => 'yappo',
        },
        {
            id   => 3,
            name => 'walf443',
        },
    ]);

=item C<$update_row_count = $teng-E<gt>update($table_name, \%update_row_data, [\%update_condition])>

Calls UPDATE on C<$table_name>, with values specified in C<%update_ro_data>, and returns the number of rows updated. You may optionally specify C<%update_condition> to create a conditional update query.

    my $update_row_count = $teng->update('user',
        {
            name => 'nomaneko',
        },
        {
            id => 1
        }
    );
    # Executes UPDATE user SET name = 'nomaneko' WHERE id = 1

You can also call update on a row object:

    my $row = $teng->single('user',{id => 1});
    $row->update({name => 'nomaneko'});

You can use the set_column method:

    my $row = $teng->single('user', {id => 1});
    $row->set_column( name => 'yappo' );
    $row->update;

you can column update by using column method:

    my $row = $teng->single('user', {id => 1});
    $row->name('yappo');
    $row->update;

=item C<$updated_row_count = $teng-E<gt>do_update($table_name, \%set, \%where)>

This is low level API for UPDATE. Normally, you should use update method instead of this.

This method does not deflate \%args.

=item C<$delete_row_count = $teng-E<gt>delete($table, \%delete_condition)>

Deletes the specified record(s) from C<$table> and returns the number of rows deleted. You may optionally specify C<%delete_condition> to create a conditional delete query.

    my $rows_deleted = $teng->delete( 'user', {
        id => 1
    } );
    # Executes DELETE FROM user WHERE id = 1

You can also call delete on a row object:

    my $row = $teng->single('user', {id => 1});
    $row->delete

=item C<$itr = $teng-E<gt>search($table_name, [\%search_condition, [\%search_attr]])>

simple search method.
search method get Teng::Iterator's instance object.

see L<Teng::Iterator>

get iterator:

    my $itr = $teng->search('user',{id => 1},{order_by => 'id'});

get rows:

    my @rows = $teng->search('user',{id => 1},{order_by => 'id'});

=item C<$row = $teng-E<gt>single($table_name, \%search_condition)>

get one record.
give back one case of the beginning when it is acquired plural records by single method.

    my $row = $teng->single('user',{id =>1});

=item C<$itr = $teng-E<gt>search_named($sql, [\%bind_values, [$table_name]])>

execute named query

    my $itr = $teng->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
It's useful in case use IN statement.

    # SELECT * FROM user WHERE id IN (?,?,?);
    # bind [1,2,3]
    my $itr = $teng->search_named(q{SELECT * FROM user WHERE id IN :ids}, {ids => [1, 2, 3]});

If you give table_name. It is assumed the hint that makes Teng::Row's Object.

=item C<$itr = $teng-E<gt>search_by_sql($sql, [\@bind_values, [$table_name]])>

execute your SQL

    my $itr = $teng->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);

If $table is specified, it set table information to result iterator.
So, you can use table row class to search_by_sql result.

=item C<$row = $teng-E<gt>single_by_sql($sql, [\@bind_values, [$table_name]])>

get one record from your SQL.

    my $row = $teng->single_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user');

This is a shortcut for

    my $row = $teng->search_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user')->next;

But optimized implementation.

=item C<$row = $teng-E<gt>single_named($sql, [\%bind_values, [$table_name]])>

get one record from execute named query

    my $row = $teng->single_named(q{SELECT id,name FROM user WHERE id = :id LIMIT 1}, {id => 1}, 'user');

This is a shortcut for

    my $row = $teng->search_named(q{SELECT id,name FROM user WHERE id = :id LIMIT 1}, {id => 1}, 'user')->next;

But optimized implementation.

=item C<$sth = $teng-E<gt>execute($sql, [\@bind_values])>

execute query and get statement handler.
and will be inserted caller's file and line as a comment in the SQL if $ENV{TENG_SQL_COMMENT} or sql_comment is true value.

=item C<$teng-E<gt>txn_scope>

Creates a new transaction scope guard object.

    do {
        my $txn = $teng->txn_scope;

        $row->update({foo => 'bar'});

        $txn->commit;
    }

If an exception occurs, or the guard object otherwise leaves the scope
before C<< $txn->commit >> is called, the transaction will be rolled
back by an explicit L</txn_rollback> call. In essence this is akin to
using a L</txn_begin>/L</txn_commit> pair, without having to worry
about calling L</txn_rollback> at the right places. Note that since there
is no defined code closure, there will be no retries and other magic upon
database disconnection.

=item C<$txn_manager = $teng-E<gt>txn_manager>

Get the DBIx::TransactionManager instance.

=item C<$teng-E<gt>txn_begin>

start new transaction.

=item C<$teng-E<gt>txn_commit>

commit transaction.

=item C<$teng-E<gt>txn_rollback>

rollback transaction.

=item C<$teng-E<gt>txn_end>

finish transaction.

=item C<$teng-E<gt>do($sql, [\%option, @bind_values])>

Execute the query specified by C<$sql>, using C<%option> and C<@bind_values> as necessary. This pretty much a wrapper around L<http://search.cpan.org/dist/DBI/DBI.pm#do>

=item C<$teng-E<gt>dbh>

get database handle.

=item C<$teng-E<gt>connect(\@connect_info)>

connect database handle.

connect_info is [$dsn, $user, $password, $options].

If you give \@connect_info, create new database connection.

=item C<$teng-E<gt>disconnect()>

Disconnects from the currently connected database.

=item C<$teng-E<gt>suppress_row_objects($flag)>

set row object creation mode.

=item C<$teng-E<gt>load_plugin();>

 $teng->load_plugin($plugin_class, $options);

This imports plugin class's methods to C<$teng> class
and it calls $plugin_class's init method if it has.

 $plugin_class->init($teng, $options);

If you want to change imported method name, use C<alias> option.
for example:

 YourDB->load_plugin('BulkInsert', { alias => { bulk_insert => 'isnert_bulk' } });

BulkInsert's "bulk_insert" method is imported as "insert_bulk".

=item C<$teng-E<gt>handle_error>

handling error method.

=item How do you use display the profiling result?

use L<Devel::KYTProf>.

=back

=head1 TRIGGERS

Teng does not support triggers (NOTE: do not confuse it with SQL triggers - we're talking about Perl level triggers). If you really want to hook into the various methods, use something like L<Moose>, L<Mouse>, and L<Class::Method::Modifiers>.

=head1 SEE ALSO

=head2 Fork

This module was forked from L<DBIx::Skinny>, around version 0.0732.
many incompatible changes have been made.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHORS

Atsushi Kobayashi  C<< <nekokak __at__ gmail.com> >>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 SUPPORT

  irc: #dbix-skinny@irc.perl.org

  ML: http://groups.google.com/group/dbix-skinny

=head1 REPOSITORY

  git clone git://github.com/nekokak/p5-teng.git  

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, the Teng L</AUTHOR>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

