package DBIx::Skin;
use strict;
use warnings;
use Carp ();
use Class::Load ();
use DBI;
use DBIx::Skin::Row;
use DBIx::Skin::Iterator;
use DBIx::Skin::Schema;
use DBIx::TransactionManager 1.02;
use DBIx::Skin::QueryBuilder;
use Class::Accessor::Lite
   rw => [ qw(
        connect_info
        on_connect_do
        dbh
        schema
        schema_class
        suppress_row_objects
        sql_builder
        owner_pid
        driver_name
    )]
;

our $VERSION = '0.0732';

sub load_plugin {
    my ($class, $pkg, $opt) = @_;
    $pkg = $pkg =~ s/^\+// ? $pkg : "DBIx::Skin::Plugin::$pkg";
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

    unless ($self->connect_info || $self->dbh) {
        Carp::croak("'dbh' or 'connect_info' is required.");
    }

    if ( ! $self->dbh ) {
        $self->connect;
    } else {
        $self->_prepare_from_dbh( $self->dbh );
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

    my $dbh = DBI->connect(@$connect_info)
        or Carp::croak("Connection error: " . $DBI::errstr);

    $self->dbh( $dbh );

    my $on_connect_do = $self->on_connect_do;
    if (not ref($on_connect_do)) {
        $self->do($on_connect_do);
    } elsif (ref($on_connect_do) eq 'CODE') {
        $on_connect_do->($self);
    } elsif (ref($on_connect_do) eq 'ARRAY') {
        $self->do($_) for @$on_connect_do;
    } else {
        Carp::croak('Invalid on_connect_do: '.ref($on_connect_do));
    }

    $self->_prepare_from_dbh( $dbh );
    return $self;
}

sub _prepare_from_dbh {
    my ($self, $dbh) = @_;

# copied from old ->connect.
#    if ( $self->{owner_pid} != $$ ) {
#        $self->{owner_pid} = $$;
#        $dbh->{InactiveDestroy} = 1;
#        $dbh = $self->reconnect;
#    }
#    unless ($dbh && $dbh->FETCH('Active') && $dbh->ping) {
#        $dbh = $self->reconnect;
#    }

    $self->driver_name($dbh->{Driver}->{Name});
    my $builder = $self->sql_builder;
    if (! $builder ) {
        # XXX Hackish
        $builder = DBIx::Skin::QueryBuilder->new(driver => $self->driver_name );
        $self->sql_builder( $builder );
    }

    return $self;
}

sub _guess_table_name {
    my ($class, $sql) = @_;

    if ($sql =~ /\sfrom\s+([\w]+)\s*/si) {
        return $1;
    }
    return;
}

sub _execute {
    my ($self, $sql, $binds, $table) = @_;
    my $dbh = $self->dbh;
    my $sth;
    eval {
        $sth = $dbh->prepare($sql);
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

sub _insert_or_replace {
    my ($self, $prefix, $table_name, $args) = @_;

    my $schema = $self->schema;

    my $values = {};
    for my $col (keys %{$args}) {
        $values->{$col} = $schema->call_deflate($table_name, $col, $args->{$col});
    }

    my ( $sql, @binds ) =
      $self->sql_builder->insert( $table_name, $values,
        { prefix => $prefix } );

    $self->_execute($sql, \@binds, $table_name);

    my $table = $schema->get_table($table_name);
    my $pk = $table->primary_keys();

    if (scalar(@$pk) == 1 && not defined $values->{$pk->[0]}) {
        $values->{$pk->[0]} = $self->_last_insert_id($table_name);
    }

    return $values if $self->suppress_row_objects;

    my $row_class = $schema->get_row_class($self, $table_name);

    my $obj = $row_class->new(
        {
            row_data   => $values,
            skin     => $self,
            table_name => $table_name,
        }
    );

    $obj;
}

sub insert {
    my ($self, $table, $args) = @_;
    $self->_insert_or_replace('INSERT', $table, $args);
}

sub replace {
    my ($self, $table, $args) = @_;
    $self->_insert_or_replace('REPLACE', $table, $args);
}

sub search_rs {
    my ($self, $table_name, $where, $opt) = @_;

    my $builder = $self->sql_builder;
    my $table = $self->schema->get_table( $table_name );
    if (! $table) {
        Carp::croak("No such table $table_name");
    }

    my ($sql, @binds) = $builder->select(
        $table_name,
        $table->columns,
        $where,
        $opt
    );

    return scalar($self->search_by_sql($sql, \@binds, $table_name));
}

sub single {
    my ($self, $table_name, $where, $opt) = @_;
    $opt->{limit} = 1;
    $self->search_rs($table_name, $where, $opt)->next;
}

sub search_by_sql {
    my ($self, $sql, $bind, $table_name) = @_;

    $table_name ||= $self->_guess_table_name( $sql );
    my $sth = $self->_execute($sql, $bind);
    my $itr = DBIx::Skin::Iterator->new(
        skin         => $self,
        sth            => $sth,
        sql            => $sql,
        row_class      => defined($table_name) ? $self->schema->get_row_class($self, $table_name) : 'DBIx::Skin::AnonRow',
        table_name     => $table_name,
        suppress_objects => $self->suppress_row_objects,
    );
    return wantarray ? $itr->all : $itr;
}

sub update {
    my ($self, $table, $args, $where) = @_;

    my $schema = $self->schema;

    my $values = {};
    for my $col (keys %{$args}) {
       $values->{$col} = $schema->call_deflate($table, $col, $args->{$col});
    }

    my $builder = $self->sql_builder;
    my ($sql, @binds) = $builder->update( $table, $values, $where );
    my $sth = $self->_execute($sql, \@binds, $table);
    my $rows = $sth->rows;
    $sth->finish;

    return $rows;
}

sub delete {
    my ($self, $table, $where) = @_;

    my $builder = $self->sql_builder;
    my ( $sql, @binds ) = $builder->delete( $table, $where );
    my $sth = $self->_execute($sql, \@binds, $table);
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
# db handling
sub reconnect {
    my $self = shift;
    $self->disconnect();
    $self->connect(@_);
}

sub disconnect {
    my $self = shift;
    $self->dbh(undef);
}

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

# XXX: for mixin? by nekokak@2011011
sub count {
    my ($self, $table, $column, $where) = @_;

    my $select = $self->sql_builder->new_select();

    $select->add_select(\"COUNT($column)");
    $select->add_from($table);
    $select->add_where($_ => $where->{$_}) for keys %{ $where || {} };

    my $sql = $select->as_sql();
    my @bind = $select->bind();

    my ($cnt) = $self->dbh->selectrow_array($sql, {}, @bind);
    return $cnt;
}

sub search {
    my ($self, $table_name, $where, $opt) = @_;

    my $iter = $self->search_rs($table_name, $where, $opt);
    return wantarray ? $iter->all : $iter;
}

# XXX: i wish modify IF by nekokak@20110111
sub search_named {
    my ($self, $sql, $args, $opts, $table) = @_;

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

    $self->search_by_sql($sql, \@bind, $table);
}

sub _last_insert_id {
    my ($self, $table) = @_;

    my $dbh = $self->dbh;
    my $driver = $self->driver_name;
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

sub handle_error {
    my ($self, $stmt, $bind, $reason) = @_;
    require Data::Dumper;

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
    
    my $skin = Your::Model->new(\%args);
    # insert new record.
    my $row = $skin->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'});

    $row = $skin->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
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

    package MyApp::Model::Row::Camelizedtable_name;
    use base qw(DBIx::Skin::Row);

Note that your table name will be camelized using String::CamelCase.

=head1 METHODS

DBIx::Skin provides a number of methods to all your classes, 

=over

=item $skin->new([\%connection_info])

create your skin instance.
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

=item $skin->insert($table_name, \%row_data)

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

=item $skin->create($table_name, \%row_data)

insert method alias.

=item $skin->replace($table_name, \%row_data)

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

=item $skin->update($table_name, \%update_row_data, [\%update_condition])

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

=item $skin->delete($table, \%delete_condition)

delete record. return delete row count.

example:

    my $delete_row_count = Your::Model->delete('user',{
        id => 1,
    });

or

    # see) DBIx::Skin::Row's POD
    my $row = Your::Model->single('user', {id => 1});
    $row->delete

=item $skin->find_or_create($table, \%values)

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

=item $skin->find_or_insert($table, \%values)

find_or_create method alias.

=item $skin->search($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search method get DBIx::Skin::Iterator's instance object.

see L<DBIx::Skin::Iterator>

get iterator:

    my $itr = Your::Model->search('user',{id => 1},{order_by => 'id'});

get rows:

    my @rows = Your::Model->search('user',{id => 1},{order_by => 'id'});

See L</ATTRIBUTES> for more information for \%search_attr.

=item $skin->search_rs($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search_rs method always get DBIx::Skin::Iterator's instance object.

This method does the same exact thing as search() except it will always return a iterator, even in list context.

=item $skin->single($table_name, \%search_condition)

get one record.
give back one case of the beginning when it is acquired plural records by single method.

    my $row = Your::Model->single('user',{id =>1});

=item $skin->count($table_name, $target_column, [\%search_condition])

get simple count

    my $cnt = Your::Model->count('user' => 'id', {age => 30});

=item $skin->search_named($sql, [\%bind_values, [\@sql_parts, [$table_name]]])

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

=item $skin->search_by_sql($sql, [\@bind_vlues, [$table_name]])

execute your SQL

    my $itr = Your::Model->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);

If $table is specified, it set table infomation to result iterator.
So, you can use table row class to search_by_sql result.

=item $skin->txn_scope

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

=item $skin->do($sql, [$option, $bind_values])

execute your query.

See) L<http://search.cpan.org/dist/DBI/DBI.pm#do>

=item $skin->dbh

get database handle.

=item $skin->connect([\%connection_info])

connect database handle.

If you give \%connection_info, create new database connection.

=item $skin->reconnect(\%connection_info)

re connect database handle.

If you give \%connection_info, create new database connection.

=item $skin->disconnect()

Disconnects from the currently connected database.

=item $skin->suppress_row_objects($flag)

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

  git clone git://github.com/nekokak/p5-dbix-skin.git  

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Atsushi Kobayashi C<< <nekokak __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

