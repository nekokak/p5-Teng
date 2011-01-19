package Teng;
use strict;
use warnings;
use Carp ();
use Class::Load ();
use DBI;
use Teng::Row;
use Teng::Iterator;
use Teng::Schema;
use DBIx::TransactionManager 1.02;
use Teng::QueryBuilder;
use Class::Accessor::Lite
   rw => [ qw(
        connect_info
        on_connect_do
        schema
        schema_class
        suppress_row_objects
        sql_builder
        owner_pid
        driver_name
    )]
;

our $VERSION = '0.04';

sub load_plugin {
    my ($class, $pkg, $opt) = @_;
    $pkg = $pkg =~ s/^\+// ? $pkg : "Teng::Plugin::$pkg";
    Class::Load::load_class($pkg);

    no strict 'refs';
    for my $meth ( @{"${pkg}::EXPORT"} ) {
        my $dest_meth =
          ( $opt->{alias} && $opt->{alias}->{$meth} )
          ? $opt->{alias}->{$meth}
          : $meth;
        *{"${class}::${dest_meth}"} = *{"${pkg}::$meth"};
    }

    $pkg->init($pkg) if $pkg->can('init');
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $self = bless {
        schema_class => "$class\::Schema",
        %args,
        owner_pid => $$,
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

# forcefully connect
sub connect {
    my ($self, @args) = @_;

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

    $self->_prepare_from_dbh;
}

sub reconnect {
    my $self = shift;

    if ($self->txn_manager->in_transaction) {
        Carp::confess("You're in a middle of a transaction, so I'm going to die");
    }

    $self->disconnect();
    $self->connect(@_);
}

sub disconnect {
    my $self = shift;
    $self->{dbh} = undef;
}

sub _prepare_from_dbh {
    my $self = shift;

    $self->driver_name($self->{dbh}->{Driver}->{Name});
    my $builder = $self->sql_builder;
    if (! $builder ) {
        # XXX Hackish
        $builder = Teng::QueryBuilder->new(driver => $self->driver_name );
        $self->sql_builder( $builder );
    }
}

sub dbh {
    my $self = shift;

    if ( $self->owner_pid != $$ ) {
        $self->owner_pid($$);
        $self->{dbh}->{InactiveDestroy} = 1;
        $self->reconnect;
        return $self->{dbh};
    }

    unless ($self->{dbh} && $self->{dbh}->FETCH('Active') && $self->{dbh}->ping) {
        $self->reconnect;
    }

    $self->{dbh};
}

sub _execute {
    my ($self, $sql, $binds, $table) = @_;

    my $sth;
    eval {
        $sth = $self->dbh->prepare($sql);
        $sth->execute(@{$binds || []});
    };
    if ($@) {
        $self->handle_error($sql, $binds, $@);
    }

    if (! defined wantarray ) {
        $sth->finish;
        return;
    }
    return $sth;
}

sub _last_insert_id {
    my ($self, $table_name) = @_;

    my $driver = $self->driver_name;
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

sub _insert {
    my ($self, $table_name, $args, $prefix) = @_;

    $prefix ||= 'INSERT';
    my $table = $self->schema->get_table($table_name);

    for my $col (keys %{$args}) {
        $args->{$col} = $table->call_deflate($col, $args->{$col});
    }

    my ($sql, @binds) = $self->sql_builder->insert( $table_name, $args, { prefix => $prefix } );
    $self->_execute($sql, \@binds, $table_name);
}

sub fast_insert {
    my ($self, $table_name, $args, $prefix) = @_;

    $self->_insert($table_name, $args, $prefix);
    $self->_last_insert_id($table_name);
}

sub insert {
    my ($self, $table_name, $args, $prefix) = @_;

    $self->_insert($table_name, $args, $prefix);

    my $table = $self->schema->get_table($table_name);
    my $pk = $table->primary_keys();
    if (scalar(@$pk) == 1 && not defined $args->{$pk->[0]}) {
        $args->{$pk->[0]} = $self->_last_insert_id($table_name);
    }

    return $args if $self->suppress_row_objects;

    $table->row_class->new(
        {
            row_data   => $args,
            teng       => $self,
            table_name => $table_name,
        }
    );
}

sub update {
    my ($self, $table_name, $args, $where) = @_;

    my $table = $self->schema->get_table($table_name);

    for my $col (keys %{$args}) {
       $args->{$col} = $table->call_deflate($col, $args->{$col});
    }

    my ($sql, @binds) = $self->sql_builder->update( $table_name, $args, $where );
    my $sth = $self->_execute($sql, \@binds, $table_name);
    my $rows = $sth->rows;
    $sth->finish;

    $rows;
}

sub delete {
    my ($self, $table_name, $where) = @_;

    my ($sql, @binds) = $self->sql_builder->delete( $table_name, $where );
    my $sth = $self->_execute($sql, \@binds, $table_name);
    my $rows = $sth->rows;
    $sth->finish;

    $rows;
}

#--------------------------------------------------------------------------------
# for transaction
sub txn_manager  {
    my $self = shift;
    $self->{txn_manager} ||= DBIx::TransactionManager->new($self->dbh);
}

sub txn_scope    { $_[0]->txn_manager->txn_scope    }
sub txn_begin    { $_[0]->txn_manager->txn_begin    }
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

sub search {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->schema->get_table( $table_name );
    if (! $table) {
        Carp::croak("No such table $table_name");
    }

    my ($sql, @binds) = $self->sql_builder->select(
        $table_name,
        $table->columns,
        $where,
        $opt
    );

    $self->search_by_sql($sql, \@binds, $table_name);
}

sub search_named {
    my ($self, $sql, $args, $table_name) = @_;

    my %named_bind = %{$args};
    my @bind;
    $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
        Carp::croak("'$1' does not exist in bind hash") if !exists $named_bind{$1};
        if ( ref $named_bind{$1} && ref $named_bind{$1} eq "ARRAY" ) {
            push @bind, @{ $named_bind{$1} };
            my $tmp = join ',', map { '?' } @{ $named_bind{$1} };
            "( $tmp )";
        } else {
            push @bind, $named_bind{$1};
            '?'
        }
    }ge;

    $self->search_by_sql($sql, \@bind, $table_name);
}

sub single {
    my ($self, $table_name, $where, $opt) = @_;
    $opt->{limit} = 1;
    $self->search($table_name, $where, $opt)->next;
}

sub search_by_sql {
    my ($self, $sql, $bind, $table_name) = @_;

    $table_name ||= $self->_guess_table_name( $sql );
    my $sth = $self->_execute($sql, $bind);
    my $itr = Teng::Iterator->new(
        teng             => $self,
        sth              => $sth,
        sql              => $sql,
        row_class        => $self->schema->get_row_class($table_name),
        table_name       => $table_name,
        suppress_object_creation => $self->suppress_row_objects,
    );
    return wantarray ? $itr->all : $itr;
}

sub _guess_table_name {
    my ($class, $sql) = @_;

    if ($sql =~ /\sfrom\s+([\w]+)\s*/si) {
        return $1;
    }
    return;
}

sub handle_error {
    my ($self, $stmt, $bind, $reason) = @_;
    require Data::Dumper;

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

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

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
    $row->update({name => 'nekokak'});

    $row = $teng->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
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

In Teng, you simply use Teng::Schema's domain specific languaage to define a set of tables

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

create your teng instance.

    # connect new database connection.
    my $db = Your::Model->new(+{
        dsn      => $dsn,
        username => $username,
        password => $password,
        connect_options => $connect_options,
    });

=over

=item * C<connect_info>

connect_info is [$dsn, $user, $password, $options].

=item * C<schema>

specific your schema instance.

by default auto load {YOUR_MODEL_CLASS}::Schema

=item * C<schema_class>

specific your schema class name space.

by default. {YOUR_MODEL_CLASS}::Schema

=item * C<suppress_row_objects>

set row object creation mode.

if you set off, no creation row object.

=item * C<sql_builder>

specific your sql builder instance.

=back

=item $row = $teng->insert($table_name, \%row_data)

insert new record and get inserted row object.

    my $row = $teng->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

=item $last_insert_id = $teng->fast_insert($table_name, \%row_data);

insert new record and get last_insert_id.

no creation row object.

=item $update_row_count = $teng->update($table_name, \%update_row_data, [\%update_condition])

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

=item $delete_row_count = $teng->delete($table, \%delete_condition)

Deletes the specified record(s) from C<$table> and returns the number of rows deleted. You may optionally specify C<%delete_condition> to create a conditional delete query.

    my $rows_deleted = $teng->delete( 'user', {
        id => 1
    } );
    # Executes DELETE FROM user WHERE id = 1

You can also call delete on a row object:

    my $row = $teng->single('user', {id => 1});
    $row->delete

=item $itr = $teng->search($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search method get Teng::Iterator's instance object.

see L<Teng::Iterator>

get iterator:

    my $itr = $teng->search('user',{id => 1},{order_by => 'id'});

get rows:

    my @rows = $teng->search('user',{id => 1},{order_by => 'id'});

=item $row = $teng->single($table_name, \%search_condition)

get one record.
give back one case of the beginning when it is acquired plural records by single method.

    my $row = $teng->single('user',{id =>1});

=item $itr = $teng->search_named($sql, [\%bind_values, [$table_name]])

execute named query

    my $itr = $teng->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
It's useful in case use IN statement.

    # SELECT * FROM user WHERE id IN (?,?,?);
    # bind [1,2,3]
    my $itr = $teng->search_named(q{SELECT * FROM user WHERE id IN :ids}, {id => [1, 2, 3]});

If you give table_name. It is assumed the hint that makes Teng::Row's Object.

=item $itr = $teng->search_by_sql($sql, [\@bind_vlues, [$table_name]])

execute your SQL

    my $itr = $teng->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);

If $table is specified, it set table infomation to result iterator.
So, you can use table row class to search_by_sql result.

=item $teng->txn_scope

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

=item $txn_manager = $teng->txn_manager

Get the DBIx::TransactionManager instance.

=item $teng->txn_begin

start new transaction.

=item $teng->txn_commit

commit transaction.

=item $teng->txn_rollback

rollback transaction.

=item $teng->txn_end

finish transaction.

=item $teng->do($sql, [\%option, \@bind_values])

Execute the query specified by C<$sql>, using C<%option> and C<@bind_values> as necessary. This pretty much a wrapper around L<http://search.cpan.org/dist/DBI/DBI.pm#do>

=item $teng->dbh

get database handle.

=item $teng->connect(\@connect_info)

connect database handle.

connect_info is [$dsn, $user, $password, $options].

If you give \@connect_info, create new database connection.

=item $teng->reconnect(\@connect_info)

re connect database handle.

connect_info is [$dsn, $user, $password, $options].

If you give \@connection_info, create new database connection.

=item $teng->disconnect()

Disconnects from the currently connected database.

=item $teng->suppress_row_objects($flag)

set row object creation mode.

=item $teng->load_plugin();

load Teng::Plugin's

=item $teng->handle_error

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

