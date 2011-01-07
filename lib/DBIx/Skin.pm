package DBIx::Skin;
use strict;
use warnings;
use Carp ();
use Class::Load ();
use DBI;
use DBIx::Skin::DBD;
use DBIx::Skin::Iterator;
use DBIx::Skin::Row;
use DBIx::Skin::Schema;
use Class::Accessor::Lite
   rw => [ qw(
        dsn
        username
        password
        connect_options
        dbh
        schema
        schema_class
        suppress_row_objects
        sql_builder
        parent_pid

        dbd
    )]
;

our $VERSION = '0.0732';

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        schema_class => "$class\::Schema",
        %args,
        parent_pid => $$,
    }, $class;

    if (! $self->schema) {
        my $schema_class = $self->schema_class;
        Class::Load::load_class( $schema_class );
        my $schema = $schema_class->instance;
        if (! $schema) {
            Carp::croak("schema object was not passed, and could not get schema instance from $schema_class");
        }
        $self->schema( $schema );
    }
    return $self;
}

# forcefully connect
sub connect {
    my ($self, %args) = @_;

    my $schema = $self->schema;
    my %attrs = (
        # basic defaults
        AutoCommit => 1,
        PrintError => 0,
        RaiseError => 1,
        # defaults from schema
        # any values in the instance
        %{ $self->connect_options || {} },
        # any values in the arguments!
        %{ $args{connect_options} || {} },
    );

    my $dsn      = $args{dsn}      || $self->dsn;
    my $username = $args{username} || $self->username;
    my $password = $args{password} || $self->password;

    my $dbh = DBI->connect(
        $dsn,
        $username,
        $password,
        \%attrs,
    ) or Carp::croak("Connection error: " . $DBI::errstr);

    $self->dbh( $dbh );

    if (! $self->sql_builder) {
    }

    return $self;
}

sub ensure_connected {
    my $self = shift;
    if (! $self->dbh) {
        $self->connect();
    }

    my $dbh = $self->dbh or
        Carp::croak("ensure_connected: failed to connect to database");
    my $driver_name = $dbh->{Driver}->{Name};
    my $builder = $self->sql_builder;
    if (! $builder ) {
        # XXX Hackish
        require SQL::Maker;
        $builder = SQL::Maker->new(driver => $driver_name );
        $self->sql_builder( $builder );
    }

    my $dbd = $self->dbd;
    if (! $dbd) {
        $dbd = DBIx::Skin::DBD->new( $driver_name );
        $self->dbd( $dbd );
    }
}

sub _guess_table_name {
    my ($class, $sql) = @_;

    if ($sql =~ /\sfrom\s+([\w]+)\s*/si) {
        return $1;
    }
    return;
}

sub _get_row_class {
    my ($class, $sql, $table) = @_;

    $table ||= $class->_guess_table_name($sql)||'';
    if ($table) {
        return $class->schema->schema_info->{$table}->{row_class};
    } else {
        return $class->_attributes->{_common_row_class} ||= do {
            my $row_class = join '::', $class->_attributes->{klass}, 'Row';
            DBIx::Skin::Util::load_class($row_class) or do {
                no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skin::Row');
            };
            $row_class;
        };
    }
}

sub _execute {
    my ($self, $sql, $binds, $table) = @_;
    my $dbh = $self->dbh; # XXX ensure_connected
    my $sth = $dbh->prepare($sql);
    $sth->execute(@{$binds || []});

    if (! defined wantarray ) {
        $sth->finish;
        return;
    }
    return $sth;
}

sub _insert_or_replace {
    my ($self, $is_replace, $tablename, $args) = @_;

    $self->ensure_connected;
    my $schema = $self->schema;

    # deflate
#    for my $col (keys %{$args}) {
#        $args->{$col} = $schema->call_deflate($col, $args->{$col});
#    }

#    my ($columns, $bind_columns, $quoted_columns) = $class->_set_columns($args, 1);

    my ($sql, @binds) = $self->sql_builder->insert( $tablename, $args );
    if ($is_replace) {
        $sql =~ s/^\s*INSERT\b/REPLACE/;
    }

    $self->_execute($sql, \@binds, $tablename);

    my $table = $schema->get_table($tablename);
    my $pk = $table->primary_keys();

    if (not ref $pk && not defined $args->{$pk}) {
        $args->{$pk} = $self->_last_insert_id($tablename);
    }

    my $row_class = $schema->get_row_class($self, $tablename);
    return $args if $self->suppress_row_objects;

    my $obj = $row_class->new(
        {
            row_data       => $args,
            skinny         => $self,
            opt_table_info => $table,
        }
    );
    $obj->setup;

    $obj;
}

*create = \*insert;
sub insert {
    my ($self, $table, $args) = @_;

    my $schema = $self->schema;
    $schema->call_trigger( pre_insert => $self, $table, $args );
    my $obj = $self->_insert_or_replace(0, $table, $args);
    $schema->call_trigger( post_insert => $self, $table, $obj );

    $obj;
}

sub resultset {
    my ($self, $args) = @_;
    $args->{skinny} = $self;
    $self->dbd->query_builder_class->new($args);
}

sub search_rs {
    my ($self, $table, $where, $opt) = @_;

    my $cols = $opt->{select} || do {
        my $table = $self->schema->get_table( $table );
        unless ( $table ) {
            Carp::croak("Table object does not exist for table '$table'");
        }
        $table->columns;
    };

    my $rs = $self->resultset(
        {
            select => $cols,
            from   => [$table],
        }
    );

    if ( $where ) {
        $rs->add_where(%$where);
    }

    $rs->limit(  $opt->{limit}  ) if $opt->{limit};
    $rs->offset( $opt->{offset} ) if $opt->{offset};

    if (my $terms = $opt->{order_by}) {
        $terms = [$terms] unless ref($terms) eq 'ARRAY';
        my @orders;
        for my $term (@{$terms}) {
            my ($col, $case);
            if (ref($term) eq 'HASH') {
                ($col, $case) = each %$term;
            } else {
                $col  = $term;
                $case = 'ASC';
            }
            push @orders, { column => $col, desc => $case };
        }
        $rs->order(\@orders);
    }

    if (my $terms = $opt->{having}) {
        for my $col (keys %$terms) {
            $rs->add_having($col => $terms->{$col});
        }
    }

    $rs->for_update(1) if $opt->{for_update};

    return $rs;
}

sub single {
    my ($self, $table, $where, $opt) = @_;
    $opt->{limit} = 1;
    $self->search_rs($table, $where, $opt)->retrieve->next;
}

sub _get_sth_iterator {
    my ($self, $sql, $sth, $opt_table_info) = @_;

    return DBIx::Skin::Iterator->new(
        skinny         => $self,
        sth            => $sth,
        sql            => $sql,
        row_class      => $self->schema->get_row_class($self, $opt_table_info),
        opt_table_info => $opt_table_info,
        suppress_objects => $self->suppress_row_objects,
    );
}

sub search_by_sql {
    my ($self, $sql, $bind, $opt_table_info) = @_;

    $self->ensure_connected;

    my $sth = $self->_execute($sql, $bind);
    my $itr = $self->_get_sth_iterator($sql, $sth, $opt_table_info);
    return wantarray ? $itr->all : $itr;
}

sub update {
    my ($self, $table, $args, $where) = @_;

    $self->ensure_connected;

    my $schema = $self->schema;
    $schema->call_trigger('pre_update', $self, $table, $args);

# XXX skip deflate
#    my $values = {};
#    for my $col (keys %{$args}) {
#       $values->{$col} = $schema->call_deflate($col, $args->{$col});
#    }

    my $builder = $self->sql_builder;
    my ($sql, @binds) = $builder->update( $table, $args, $where );
    my $sth = $self->_execute($sql, \@binds, $table);
    my $rows = $sth->rows;
    $sth->finish;

    $schema->call_trigger('post_update', $self, $table, $rows);

    return $rows;
}

sub delete {
    my ($self, $table, $where) = @_;

    $self->ensure_connected;

    my $schema = $self->schema;
    $schema->call_trigger('pre_delete', $self, $table, $where);

    my $builder = $self->sql_builder;
    my ( $sql, @binds ) = $builder->delete( $table, $where );
    my $sth = $self->_execute($sql, \@binds, $table);
    my $rows = $sth->rows;

    $schema->call_trigger('post_delete', $self, $table, $rows);
    $sth->finish;

    $rows;
}

1;

__END__


use DBI;
use DBIx::Skin::Iterator;
use DBIx::Skin::DBD;
use DBIx::Skin::Row;
use DBIx::Skin::Util;
use DBIx::TransactionManager 1.02;
use Carp ();
use Storable ();
use Class::Load ();

use Class::Accessor::Lite (
    ro => [qw/schema/],
    rw => [qw/suppress_row_objects/],
);

sub import {
    my ($class, %opt) = @_;

    return if $class ne 'DBIx::Skin';

    my $caller = caller;

    my $schema = $opt{schema} || "$caller\::Schema";
    Class::Load::try_load_class($schema); # XXX Why is it optional? -- tokuhirom@20110107

    my $_attributes = +{
        schema          => $schema,
    };

    {
        no strict 'refs';
        push @{"${caller}::ISA"}, $class;
        *{"$caller\::_new_attributes"} = sub { ref $_[0] ? $_[0] : $_attributes }; # TODO: rename or remove? -- tokuhirom@20110107
    }

    strict->import;
    warnings->import;
}

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $attr = $class->_new_attributes;

    my $self = bless +{
        schema               => $attr->{schema},
        suppress_row_objects => 0,
        last_pid             => $$,
        _common_row_class    => undef,
    }, $class;

    $self->connect_info(\%args);
    if ($args{dbh}) {
        $self->{dbh} = $args{dbh};
        $self->_setup_dbd({dbh => $args{dbh}});
    } else {
        $self->connect();
    }

    return $self;
}

#--------------------------------------------------------------------------------
# for transaction

sub txn_manager  {
    my $self = shift;

    $self->{txn_manager} ||= do {
        my $dbh = $self->dbh;
        unless ($dbh) { # XXX this assertion is maybe trash. -- tokuhirom@20110107
            Carp::croak("dbh is not found.");
        }
        DBIx::TransactionManager->new($dbh);
    };
}

sub txn_scope    { $_[0]->txn_manager->txn_scope    }
sub txn_begin    { $_[0]->txn_manager->txn_begin    }
sub txn_rollback { $_[0]->txn_manager->txn_rollback }
sub txn_commit   { $_[0]->txn_manager->txn_commit   }
sub txn_end      { $_[0]->txn_manager->txn_end      }

#--------------------------------------------------------------------------------
# db handling
sub connect_info {
    my ($self, $connect_info) = @_;

    if (@_==2) {
        # setter
        $_[0]->{connect_info} = $_[1];
        $_[0]->_setup_dbd($_[1]);
    } else {
        return $_[0]->{connect_info};
    }
}

sub connect {
    my $self = shift;

    $self->connect_info(@_) if scalar @_ >= 1;
    my $connect_info = $self->connect_info;

    if (!$self->{dbh} ) {
        $self->{dbh} = DBI->connect(
            $connect_info->{dsn},
            $connect_info->{username},
            $connect_info->{password},
            { RaiseError => 1, PrintError => 0, AutoCommit => 1, %{ $connect_info->{connect_options} || {} } }
        ) or Carp::croak("Connection error: " . $DBI::errstr);

        if ( my $on_connect_do = $connect_info->{on_connect_do} ) {
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

    $self->{dbh};
}

sub reconnect {
    my $self = shift;
    $self->disconnect();
    $self->connect(@_);
}

sub disconnect {
    my $self = shift;
    $self->{dbh} = undef;
}

sub _setup_dbd {
    my ($self, $args) = @_;
    my $driver_name = $args ? _guess_driver_name($args) : $self->{driver_name};
    $self->{driver_name} = $driver_name;
    $self->{dbd} = $driver_name ? DBIx::Skin::DBD->new($driver_name) : undef;
}

sub _guess_driver_name {
    my $args = shift;
    if ($args->{dbh}) {
        return $args->{dbh}->{Driver}->{Name};
    } elsif ($args->{dsn}) {
        my (undef, $driver_name,) = DBI->parse_dsn($args->{dsn}) or Carp::croak "can't parse DSN: @{[ $args->{dsn} ]}";
        return $driver_name
    }
}

sub dbd {
    Carp::croak("$_[0]->dbh is a instance method.") unless ref $_[0]; # this is a temoprary croak to refactoring. I should remove this method later. -- tokuhirom

    $_[0]->{dbd} or do {
        require Data::Dumper;
        Carp::croak("Attribute 'dbd' is not defined. Either we failed to connect, or the connection has gone away.");
    };
}

sub dbh {
    my $self = shift;

    my $dbh = $self->connect;
    if ( $self->{last_pid} != $$ ) {
        $self->{last_pid} = $$;
        $dbh->{InactiveDestroy} = 1;
        $dbh = $self->reconnect;
    }
    unless ($dbh && $dbh->FETCH('Active') && $dbh->ping) {
        $dbh = $self->reconnect;
    }
    $dbh;
}

#--------------------------------------------------------------------------------
# schema trigger call
sub call_schema_trigger {
    my ($class, $trigger, $schema, $table, $args) = @_;
    $schema->call_trigger($class, $table, $trigger, $args);
}

#--------------------------------------------------------------------------------
sub do {
    my ($self, $sql, $attr, @bind_vars) = @_;
    my $ret;
    eval { $ret = $self->dbh->do($sql, $attr, @bind_vars) };
    if ($@) {
        $self->_stack_trace('', $sql, @bind_vars ? \@bind_vars : '', $@);
    }
    $ret;
}

sub count {
    my ($self, $table, $column, $where) = @_;

    my $rs = $self->resultset(
        {
            from   => [$table],
        }
    );

    $rs->add_select("COUNT($column)" =>  'cnt');
    $self->_add_where($rs, $where);

    $rs->retrieve->next->cnt;
}

sub search {
    my ($self, $table, $where, $opt) = @_;

    my $iter = $self->search_rs($table, $where, $opt)->retrieve;
    return wantarray ? $iter->all : $iter;
}

sub search_named {
    my ($self, $sql, $args, $opts, $opt_table_info) = @_;

    $sql = sprintf($sql, @{$opts||[]});
    my %named_bind = %{$args};
    my @bind;
    $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
        Carp::croak("$1 does not exists in hash") if !exists $named_bind{$1};
        if ( ref $named_bind{$1} && ref $named_bind{$1} eq "ARRAY" ) {
            push @bind, @{ $named_bind{$1} };
            my $tmp = join ',', map { '?' } @{ $named_bind{$1} };
            "( $tmp )";
        } else {
            push @bind, $named_bind{$1};
            '?'
        }
    }ge;

    $self->search_by_sql($sql, \@bind, $opt_table_info);
}

sub find_or_new {
    my ($self, $table, $args) = @_;
    $self->single($table, $args) or do {
        $self->hash_to_row($table, $args);
    };
}

# XXX bad name? -- tokuhirom@20110107
sub hash_to_row {
    my ($self, $table, $hash) = @_;

    my $row_class = $self->_get_row_class($table, $table);
    my $row = $row_class->new(
        {
            sql            => undef,
            row_data       => $hash,
            skinny         => $self,
            opt_table_info => $table,
        }
    );
    $row->setup;
    $row;
}

sub _guess_table_name {
    my ($self, $sql) = @_;

    if ($sql =~ /\sfrom\s+([\w]+)\s*/si) {
        return $1;
    }
    return;
}

sub _get_row_class {
    my ($self, $sql, $table) = @_;

    $table ||= $self->_guess_table_name($sql)||'';
    if ($table) {
        return $self->schema->schema_info->{$table}->{row_class};
    } else {
        return $self->{_common_row_class} ||= do {
            my $klass = ref $self || $self;
            my $row_class = join '::', $klass, 'Row';
            DBIx::Skin::Util::load_class($row_class) or do {
                no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skin::Row');
            };
            $row_class;
        };
    }
}

sub _quote {
    my ($label, $quote, $name_sep) = @_;

    return $label if $label eq '*';
    return $quote . $label . $quote if !defined $name_sep;
    return join $name_sep, map { $quote . $_ . $quote } split /\Q$name_sep\E/, $label;
}

sub bind_params {
    my($self, $table, $columns, $sth) = @_;

    my $schema = $self->schema;
    my $dbd    = $self->dbd;
    my $i = 1;
    for my $column (@{ $columns }) {
        my($col, $val) = @{ $column };
        my $type = $schema->column_type($table, $col);
        my $attr = $type ? $dbd->bind_param_attributes($type) : undef;

        my $ref = ref $val;
        if ($ref eq 'ARRAY') {
            $sth->bind_param($i++, $_, $attr) for @$val;
        } elsif (not $ref) {
            $sth->bind_param($i++, $val, $attr);
        } else {
            die "you can't set bind value, arrayref or scalar. you set $ref ref value.";
        }
    }
}

sub _set_columns {
    my ($self, $args, $insert) = @_;

    my $schema = $self->schema;
    my $dbd = $self->dbd;
    my $quote = $dbd->quote;
    my $name_sep = $dbd->name_sep;

    my (@columns, @bind_columns, @quoted_columns);
    for my $col (keys %{ $args }) {
        my $quoted_col = _quote($col, $quote, $name_sep);
        if (ref($args->{$col}) eq 'SCALAR') {
            push @columns, ($insert ? ${ $args->{$col} } :"$quoted_col = " . ${ $args->{$col} });
        } else {
            push @columns, ($insert ? '?' : "$quoted_col = ?");
            push @bind_columns, [$col, $args->{$col}];
        }
        push @quoted_columns, $quoted_col;
    }

    return (\@columns, \@bind_columns, \@quoted_columns);
}

sub _insert_or_replace {
    my ($self, $is_replace, $table, $args) = @_;

    my $schema = $self->schema;

    # deflate
    for my $col (keys %{$args}) {
        $args->{$col} = $schema->call_deflate($col, $args->{$col});
    }

    my ($columns, $bind_columns, $quoted_columns) = $self->_set_columns($args, 1);

    my $sql = $is_replace ? 'REPLACE' : 'INSERT';
    $sql .= " INTO $table\n";
    $sql .= '(' . join(', ', @$quoted_columns) .')' . "\n" .
            'VALUES (' . join(', ', @$columns) . ')' . "\n";

    my $sth = $self->_execute($sql, $bind_columns, $table);
    $self->_close_sth($sth);

    my $pk = $self->schema->schema_info->{$table}->{pk};

    if (not ref $pk && not defined $args->{$pk}) {
        $args->{$pk} = $self->_last_insert_id($table);
    }

    my $row_class = $self->_get_row_class($sql, $table);
    return $args if $self->suppress_row_objects;

    my $obj = $row_class->new(
        {
            row_data       => $args,
            skinny         => $self,
            opt_table_info => $table,
        }
    );
    $obj->setup;

    $obj;
}

sub _last_insert_id {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;
    my $driver = $self->{driver_name};
    if ( $driver eq 'mysql' ) {
        return $dbh->{mysql_insertid};
    } elsif ( $driver eq 'Pg' ) {
        return $dbh->last_insert_id( undef, undef, undef, undef,{ sequence => join( '_', $table, 'id', 'seq' ) } );
    } elsif ( $driver eq 'SQLite' ) {
        return $dbh->func('last_insert_rowid');
    } elsif ( $driver eq 'Oracle' ) {
        return;
    } else {
        Carp::croak "Don't know how to get last insert id for $driver";
    }
}

*create = \*insert;
sub insert {
    my ($self, $table, $args) = @_;

    my $schema = $self->schema;
    $self->call_schema_trigger('pre_insert', $schema, $table, $args);

    my $obj = $self->_insert_or_replace(0, $table, $args);

    $self->call_schema_trigger('post_insert', $schema, $table, $obj);

    $obj;
}

sub replace {
    my ($self, $table, $args) = @_;

    my $schema = $self->schema;
    $self->call_schema_trigger('pre_insert', $schema, $table, $args);

    my $obj = $self->_insert_or_replace(1, $table, $args);

    $self->call_schema_trigger('post_insert', $schema, $table, $obj);

    $obj;
}

sub bulk_insert {
    my ($self, $table, $args) = @_;

    my $code = $self->{dbd}->can('bulk_insert') or Carp::croak "dbd don't provide bulk_insert method";
    $code->($self, $table, $args);
}

*find_or_insert = \*find_or_create;
sub find_or_create {
    my ($self, $table, $args) = @_;
    my $row = $self->single($table, $args);
    return $row if $row;
    $self->insert($table, $args)->refetch;
}

sub _add_where {
    my ($self, $stmt, $where) = @_;
    for my $col (keys %{$where}) {
        $stmt->add_where($col => $where->{$col});
    }
}

sub _execute {
    my ($self, $stmt, $args, $table) = @_;

    my ($sth, $bind);
    if ($table) {
        eval {
            $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
            $self->bind_params($table, $args, $sth);
            $sth->execute;
        };
    } else {
        $bind = $args;
        eval {
            $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
            $sth->execute(@{$args});
        };
    }

    if ($@) {
        $self->_stack_trace($sth, $stmt, $bind, $@);
    }
    return $sth;
}

# stack trace
sub _stack_trace {
    my ($self, $sth, $stmt, $bind, $reason) = @_;
    require Data::Dumper;

    if ($sth) {
        $self->_close_sth($sth);
    }

    $stmt =~ s/\n/\n          /gm;
    Carp::croak sprintf <<"TRACE", $reason, $stmt, Data::Dumper::Dumper($bind);
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ DBIx::Skin 's Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
}

sub _close_sth {
    my ($self, $sth) = @_;
    $sth->finish;
    undef $sth;
}

1;

__END__
=head1 NAME

DBIx::Skin - simple DBI wrapper/ORMapper

=head1 SYNOPSIS

create your db model base class.

    package Your::Model;
    use parent 'DBIx::Skin';
    1;
    
create your db schema class.
See DBIx::Skin::Schema for docs on defining schema class.

    package Your::Model::Schema;
    use DBIx::Skin::Schema;
    table {
        name 'user';
        pk 'id';
        columns qw( foo bar baz );
    };
    1;
    
in your script.

    use Your::Model;
    
    my $skinny = Your::Model->new(\%args);
    # insert new record.
    my $row = $skinny->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'});

    $row = $skinny->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete('user');

=head1 DESCRIPTION

DBIx::Skin is simple DBI wrapper and simple O/R Mapper.
It aims to be lightweight, with minimal dependencies so it's easier to install. 

=head1 ARCHITECTURE

DBIx::Skin classes are comprised of three distinct components:

=head2 MODEL

The C<model> is where you say 

    package MyApp::Model;
    use DBIx::Skin;

This is the entry point to using DBIx::Skin. You connect, insert, update, delete, select stuff using this object.

=head2 SCHEMA

The C<schema> is a simple class that describes your table definitions. Note that this is different from DBIx::Class terms. DBIC's schema is equivalent to DBIx::Skin's model + schema, where the actual schema information is scattered across the result classes.

In DBIx::Skin, you simply use DBIx::Skin::Schema's domain specific languaage to define a set of tables

    package MyApp::Model::Schema;
    use DBIx::Skin::Schema;

    install_table $table_name => schema {
        pk $primary_key_column;
        columns qw(
            column1
            column2
            column3
        );
    }

    ... and other tables ...

=head2 ROW

Unlike DBIx::Class, you don't need to have a set of classes that represent a row type (i.e. "result" classes in DBIC terms). In DBIx::Skin, the row objects are blessed into anonymous classes that inherit from DBIx::Skin::Row, so you don't have to create these classes if you just want to use some simple queries.

If you want to define methods to be performed by your row objects, simply create a row class like so:

    package MyApp::Model::Row::CamelizedTableName;
    use base qw(DBIx::Skin::Row);

Note that your table name will be camelized using String::CamelCase.

=head1 METHODS

DBIx::Skin provides a number of methods to all your classes, 

=over

=item $skinny->new([\%connection_info])

create your skinny instance.
It is possible to use it even by the class method.

$connection_info is optional argment.

When $connection_info is specified,
new method connect new DB connection from $connection_info.

When $connection_info is not specified,
it becomes use already setup connection or it doesn't do at all.

example:

    my $db = Your::Model->new;

or

    # connect new database connection.
    my $db = Your::Model->new(+{
        dsn      => $dsn,
        username => $username,
        password => $password,
        connect_options => $connect_options,
    });

or

    my $dbh = DBI->connect();
    my $db = Your::Model->new(+{
        dbh => $dbh,
    });

=item $skinny->insert($table_name, \%row_data)

insert new record and get inserted row object.

if insert to table has auto increment then return $row object with fill in key column by last_insert_id.

example:

    my $row = Your::Model->insert('user',{
        id   => 1,
        name => 'nekokak',
    });
    say $row->id; # show last_insert_id()

or

    my $db = Your::Model->new;
    my $row = $db->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

=item $skinny->create($table_name, \%row_data)

insert method alias.

=item $skinny->replace($table_name, \%row_data)

The data that already exists is replaced. 

example:

    Your::Model->replace('user',{
        id   => 1,
        name => 'tokuhirom',
    });

or 

    my $db = Your::Model->new;
    my $row = $db->replace('user',{
        id   => 1,
        name => 'tokuhirom',
    });

=item $skinny->bulk_insert($table_name, \@rows_data)

Accepts either an arrayref of hashrefs.
each hashref should be a structure suitable
forsubmitting to a Your::Model->insert(...) method.

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

=item $skinny->update($table_name, \%update_row_data, [\%update_condition])

$update_condition is optional argment.

update record.

example:

    my $update_row_count = Your::Model->update('user',{
        name => 'nomaneko',
    },{ id => 1 });

or 

    # see) DBIx::Skin::Row's POD
    my $row = Your::Model->single('user',{id => 1});
    $row->update({name => 'nomaneko'});

=item $skinny->delete($table, \%delete_condition)

delete record. return delete row count.

example:

    my $delete_row_count = Your::Model->delete('user',{
        id => 1,
    });

or

    # see) DBIx::Skin::Row's POD
    my $row = Your::Model->single('user', {id => 1});
    $row->delete

=item $skinny->find_or_create($table, \%values)

create record if not exsists record.

return DBIx::Skin::Row's instance object.

example:

    my $row = Your::Model->find_or_create('usr',{
        id   => 1,
        name => 'nekokak',
    });

NOTICE: find_or_create has bug.

reproduction example:

    my $row = Your::Model->find_or_create('user',{
        id   => 1,
        name => undef,
    });

In this case, it becomes an error by insert.

If you want to do the same thing in this case,

    my $row = Your::Model->single('user', {
        id   => 1,
        name => \'IS NULL',
    })
    unless ($row) {
        Your::Model->insert('user', {
            id => 1,
        });
    }

Because the interchangeable rear side is lost, it doesn't mend. 

=item $skinny->find_or_insert($table, \%values)

find_or_create method alias.

=item $skinny->search($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search method get DBIx::Skin::Iterator's instance object.

see L<DBIx::Skin::Iterator>

get iterator:

    my $itr = Your::Model->search('user',{id => 1},{order_by => 'id'});

get rows:

    my @rows = Your::Model->search('user',{id => 1},{order_by => 'id'});

See L</ATTRIBUTES> for more information for \%search_attr.

=item $skinny->search_rs($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search_rs method always get DBIx::Skin::Iterator's instance object.

This method does the same exact thing as search() except it will always return a iterator, even in list context.

=item $skinny->single($table_name, \%search_condition)

get one record.
give back one case of the beginning when it is acquired plural records by single method.

    my $row = Your::Model->single('user',{id =>1});

=item $skinny->resultset(\%options)

resultset case:

    my $rs = Your::Model->resultset(
        {
            select => [qw/id name/],
            from   => [qw/user/],
        }
    );
    $rs->add_where('name' => {op => 'like', value => "%neko%"});
    $rs->limit(10);
    $rs->offset(10);
    $rs->order({ column => 'id', desc => 'DESC' });
    my $itr = $rs->retrieve;

=item $skinny->count($table_name, $target_column, [\%search_condition])

get simple count

    my $cnt = Your::Model->count('user' => 'id', {age => 30});

=item $skinny->search_named($sql, [\%bind_values, [\@sql_parts, [$table_name]]])

execute named query

    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
It's useful in case use IN statement.

    # SELECT * FROM user WHERE id IN (?,?,?);
    # bind [1,2,3]
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id IN :ids}, {id => [1, 2, 3]});

If you give \@sql_parts,

    # SELECT * FROM user WHERE id IN (?,?,?) AND unsubscribed_at IS NOT NULL;
    # bind [1,2,3]
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id IN :ids %s}, {id => [1, 2, 3]}, ['AND unsubscribed_at IS NOT NULL']);

If you give table_name. It is assumed the hint that makes DBIx::Skin::Row's Object.

=item $skinny->search_by_sql($sql, [\@bind_vlues, [$table_name]])

execute your SQL

    my $itr = Your::Model->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);

If $opt_table_info is specified, it set table infomation to result iterator.
So, you can use table row class to search_by_sql result.

=item $skinny->txn_scope

get transaction scope object.

    do {
        my $txn = Your::Model->txn_scope;

        $row->update({foo => 'bar'});

        $txn->commit;
    }

An alternative way of transaction handling based on
L<DBIx::Skin::Transaction>.

If an exception occurs, or the guard object otherwise leaves the scope
before C<< $txn->commit >> is called, the transaction will be rolled
back by an explicit L</txn_rollback> call. In essence this is akin to
using a L</txn_begin>/L</txn_commit> pair, without having to worry
about calling L</txn_rollback> at the right places. Note that since there
is no defined code closure, there will be no retries and other magic upon
database disconnection.

=item $skinny->hash_to_row($table_name, $row_data_hash_ref)

make DBIx::Skin::Row's class from hash_ref.

    my $row = Your::Model->hash_to_row('user',
        {
            id   => 1,
            name => 'lestrrat',
        }
    );

=item $skinny->find_or_new($table_name, \%row_data)

Find an existing record from database.

If none exists, instantiate a new row object and return it.

The object will not be saved into your storage until you call "insert" in DBIx::Skin::Row on it.

    my $row = Your::Model->find_or_new('user',{name => 'nekokak'});

=item $skinny->do($sql, [$option, $bind_values])

execute your query.

See) L<http://search.cpan.org/dist/DBI/DBI.pm#do>

=item $skinny->dbh

get database handle.

=item $skinny->connect([\%connection_info])

connect database handle.

If you give \%connection_info, create new database connection.

=item $skinny->reconnect(\%connection_info)

re connect database handle.

If you give \%connection_info, create new database connection.

=item $skinny->disconnect()

Disconnects from the currently connected database.

=item $skinny->suppress_row_objects($flag)

set row object creation mode.

=back

=head1 ATTRIBUTES

=over

=item order_by

    { order_by => [ { id => 'desc' } ] }
    # or
    { order_by => { id => 'desc' } }
    # or 
    { order_by => 'name' }

=item for_update

    { for_update => 1 }

=back

=item How do you use display the profiling result?

use L<Devel::KYTProf>.

=head2 TRIGGER

    my $row = $db->insert($args);
    # pre_insert: ($db, $args, $table_name)
    # post_insert: ($db, $row, $table_name)

    my $updated_rows_count = $db->update($args);
    my $updated_rows_count = $row->update(); # example $args: +{ id => $row->id }
    # pre_update: ($db, $args, $table_name)
    # post_update: ($db, $updated_rows_count, $table_name)

    my $deleted_rows_count = $db->delete($args);
    my $deleted_rows_count = $row->delete(); # example $args: +{ id => $row->id }
    # pre_delete: ($db, $args, $table_name)
    # post_delete: ($db, $deleted_rows_count, $table_name)

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <nekokak __at__ gmail.com> >>

=head1 CONTRIBUTORS

walf443 : Keiji Yoshimi

TBONE : Terrence Brannon

nekoya : Ryo Miyake

oinume: Kazuhiro Oinuma

fujiwara: Shunichiro Fujiwara

pjam: Tomoyuki Misonou

magicalhat

Makamaka Hannyaharamitu

nihen: Masahiro Chiba

lestrrat: Daisuke Maki

tokuhirom: Tokuhiro Matsuno

=head1 SUPPORT

  irc: #dbix-skinny@irc.perl.org

  ML: http://groups.google.com/group/dbix-skinny

=head1 REPOSITORY

  git clone git://github.com/nekokak/p5-dbix-skinny.git  

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Atsushi Kobayashi C<< <nekokak __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

