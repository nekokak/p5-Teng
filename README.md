[![Actions Status](https://github.com/nekokak/p5-Teng/actions/workflows/test.yml/badge.svg)](https://github.com/nekokak/p5-Teng/actions)
# NAME

Teng - very simple DBI wrapper/ORMapper

# SYNOPSIS

    my $db = MyDB->new({ connect_info => [ 'dbi:SQLite:' ] });
    my $row = $db->insert( 'table' => {
        col1 => $value
    } );

# DESCRIPTION

Teng is very simple DBI wrapper and simple O/R Mapper.
It aims to be lightweight, with minimal dependencies so it's easier to install. 

# BASIC USAGE

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

# ARCHITECTURE

Teng classes are comprised of three distinct components:

## MODEL

The `model` is where you say 

    package MyApp::Model;
    use parent 'Teng';

This is the entry point to using Teng. You connect, insert, update, delete, select stuff using this object.

## SCHEMA

The `schema` is a simple class that describes your table definitions. Note that this is different from DBIx::Class terms.
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

## ROW

Unlike DBIx::Class, you don't need to have a set of classes that represent a row type (i.e. "result" classes in DBIC terms).
In Teng, the row objects are blessed into anonymous classes that inherit from Teng::Row,
so you don't have to create these classes if you just want to use some simple queries.

If you want to define methods to be performed by your row objects, simply create a row class like so:

    package MyApp::Model::Row::Camelizedtable_name;
    use parent qw(Teng::Row);

Note that your table name will be camelized.

# METHODS

Teng provides a number of methods to all your classes, 

- $teng = Teng->new(\\%args)

    Creates a new Teng instance.

        # connect new database connection.
        my $db = Your::Model->new(
            connect_info => [ $dsn, $username, $password, \%connect_options ]
        );

    Arguments can be:

    - `connect_info`

        Specifies the information required to connect to the database.
        The argument should be a reference to a array in the form:

            [ $dsn, $user, $password, \%options ]

        You must pass `connect_info` or `dbh` to the constructor.

    - `dbh`

        Specifies the database handle to use.

    - `no_ping`

        By default, ping before each executing query.
        If it affect performance then you can set to true for ping stopping.

    - `fields_case`

        specific DBI.pm's FetchHashKeyName.

    - `schema`

        Specifies the Teng::Schema instance to use.
        If not specified, the value specified in `schema_class` is loaded and
        instantiated for you.

    - `schema_class`

        Specifies the schema class to use.
        By default {YOUR\_MODEL\_CLASS}::Schema is used.

    - `txn_manager_class`

        Specifies the transaction manager class.
        By default DBIx::TransactionManager is used.

    - `suppress_row_objects`

        Specifies the row object creation mode. By default this value is `false`.
        If you specifies this to a `true` value, no row object will be created when
        a `SELECT` statement is issued..

    - `force_deflate_set_column`

        Specifies `set_column`, `set_columns` and column name method behaviour. By default this value is `false`.
        If you specifies this to a `true` value, `set_column` or column name method will deflate argument.

    - `sql_builder`

        Speficies the SQL builder object. By default SQL::Maker is used, and as such,
        if you provide your own SQL builder the interface needs to be compatible
        with SQL::Maker.

    - `sql_builder_class` : Str

        Speficies the SQL builder class name. By default SQL::Maker is used, and as such,
        if you provide your own SQL builder the interface needs to be compatible
        with SQL::Maker.

        Specified `sql_builder_class` is instantiated with following:

            $sql_builder_class->new(
                driver => $teng->{driver_name},
                %{ $teng->{sql_builder_args}  }
            )

        This is not used when `sql_builder` is specified.

    - `sql_builder_args` : HashRef

        Speficies the arguments for constructor of `sql_builder_class`. This is not used when `sql_builder` is specified.

    - `trace_ignore_if` : CodeRef

        Ignore to inject the SQL comment when trace\_ignore\_if's return value is true.

- `$row = $teng->insert($table_name, \%row_data)`

    Inserts a new record. Returns the inserted row object.

        my $row = $teng->insert('user',{
            id   => 1,
            name => 'nekokak',
        });

    If a primary key is available, it will be fetched after the insert -- so
    an INSERT followed by SELECT is performed. If you do not want this, use
    `fast_insert`.

- `$last_insert_id = $teng->fast_insert($table_name, \%row_data);`

    insert new record and get last\_insert\_id.

    no creation row object.

- `$teng->do_insert`

    Internal method called from `insert` and `fast_insert`. You can hook it on your responsibility.

- `$teng->bulk_insert($table_name, \@rows_data, \%opt)`

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

    You can specify `$opt` like `{ prefix => 'INSERT IGNORE INTO' }` or `{ update => { name => 'updated' } }` optionally, which will be passed to query builder.

- `$update_row_count = $teng->update($table_name, \%update_row_data, [\%update_condition])`

    Calls UPDATE on `$table_name`, with values specified in `%update_ro_data`, and returns the number of rows updated. You may optionally specify `%update_condition` to create a conditional update query.

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

    You can use the set\_column method:

        my $row = $teng->single('user', {id => 1});
        $row->set_column( name => 'yappo' );
        $row->update;

    you can column update by using column method:

        my $row = $teng->single('user', {id => 1});
        $row->name('yappo');
        $row->update;

- `$updated_row_count = $teng->do_update($table_name, \%set, \%where)`

    This is low level API for UPDATE. Normally, you should use update method instead of this.

    This method does not deflate \\%args.

- `$delete_row_count = $teng->delete($table, \%delete_condition)`

    Deletes the specified record(s) from `$table` and returns the number of rows deleted. You may optionally specify `%delete_condition` to create a conditional delete query.

        my $rows_deleted = $teng->delete( 'user', {
            id => 1
        } );
        # Executes DELETE FROM user WHERE id = 1

    You can also call delete on a row object:

        my $row = $teng->single('user', {id => 1});
        $row->delete

- `$itr = $teng->search($table_name, [\%search_condition, [\%search_attr]])`

    simple search method.
    search method get Teng::Iterator's instance object.

    see [Teng::Iterator](https://metacpan.org/pod/Teng%3A%3AIterator)

    get iterator:

        my $itr = $teng->search('user',{id => 1},{order_by => 'id'});

    get rows:

        my @rows = $teng->search('user',{id => 1},{order_by => 'id'});

- `$row = $teng->single($table_name, \%search_condition)`

    get one record.
    give back one case of the beginning when it is acquired plural records by single method.

        my $row = $teng->single('user',{id =>1});

- `$row = $teng->new_row_from_hash($table_name, \%row_data, [$sql])`

    create row object from data. (not fetch from db.)
    It's useful in such as testing.

        my $row = $teng->new_row_from_hash('user', { id => 1, foo => "bar" });
        say $row->foo; # say bar

- `$itr = $teng->search_named($sql, [\%bind_values, [$table_name]])`

    execute named query

        my $itr = $teng->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

    If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
    It's useful in case use IN statement.

        # SELECT * FROM user WHERE id IN (?,?,?);
        # bind [1,2,3]
        my $itr = $teng->search_named(q{SELECT * FROM user WHERE id IN :ids}, {ids => [1, 2, 3]});

    If you give table\_name. It is assumed the hint that makes Teng::Row's Object.

- `$itr = $teng->search_by_sql($sql, [\@bind_values, [$table_name]])`

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
    So, you can use table row class to search\_by\_sql result.

- `$row = $teng->single_by_sql($sql, [\@bind_values, [$table_name]])`

    get one record from your SQL.

        my $row = $teng->single_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user');

    This is a shortcut for

        my $row = $teng->search_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user')->next;

    But optimized implementation.

- `$row = $teng->single_named($sql, [\%bind_values, [$table_name]])`

    get one record from execute named query

        my $row = $teng->single_named(q{SELECT id,name FROM user WHERE id = :id LIMIT 1}, {id => 1}, 'user');

    This is a shortcut for

        my $row = $teng->search_named(q{SELECT id,name FROM user WHERE id = :id LIMIT 1}, {id => 1}, 'user')->next;

    But optimized implementation.

- `$sth = $teng->execute($sql, [\@bind_values])`

    execute query and get statement handler.
    and will be inserted caller's file and line as a comment in the SQL if $ENV{TENG\_SQL\_COMMENT} or sql\_comment is true value.

- `$teng->txn_scope`

    Creates a new transaction scope guard object.

        do {
            my $txn = $teng->txn_scope;

            $row->update({foo => 'bar'});

            $txn->commit;
        }

    If an exception occurs, or the guard object otherwise leaves the scope
    before `$txn->commit` is called, the transaction will be rolled
    back by an explicit ["txn\_rollback"](#txn_rollback) call. In essence this is akin to
    using a ["txn\_begin"](#txn_begin)/["txn\_commit"](#txn_commit) pair, without having to worry
    about calling ["txn\_rollback"](#txn_rollback) at the right places. Note that since there
    is no defined code closure, there will be no retries and other magic upon
    database disconnection.

- `$txn_manager = $teng->txn_manager`

    Create the transaction manager instance with specified `txn_manager_class`.

- `$teng->txn_begin`

    start new transaction.

- `$teng->txn_commit`

    commit transaction.

- `$teng->txn_rollback`

    rollback transaction.

- `$teng->txn_end`

    finish transaction.

- `$teng->do($sql, [\%option, @bind_values])`

    Execute the query specified by `$sql`, using `%option` and `@bind_values` as necessary. This pretty much a wrapper around [http://search.cpan.org/dist/DBI/DBI.pm#do](http://search.cpan.org/dist/DBI/DBI.pm#do)

- `$teng->dbh`

    get database handle.

- `$teng->connect(\@connect_info)`

    connect database handle.

    connect\_info is \[$dsn, $user, $password, $options\].

    If you give \\@connect\_info, create new database connection.

- `$teng->disconnect()`

    Disconnects from the currently connected database.

- `$teng->suppress_row_objects($flag)`

    set row object creation mode.

- `$teng->apply_sql_types($flag)`

    set SQL type application mode.

    see apply\_sql\_types in ["METHODS" in Teng::Iterator](https://metacpan.org/pod/Teng%3A%3AIterator#METHODS)

- `$teng->guess_sql_types($flag)`

    set SQL type guessing mode.
    this implies apply\_sql\_types true.

    see guess\_sql\_types in ["METHODS" in Teng::Iterator](https://metacpan.org/pod/Teng%3A%3AIterator#METHODS)

- `$teng->set_boolean_value($true, $false)`

    set scalar to correspond boolean.
    this is ignored when apply\_sql\_types is not true.

        $teng->set_boolean_value(JSON::XS::true, JSON::XS::false);

- `$teng->load_plugin();`

        $teng->load_plugin($plugin_class, $options);

    This imports plugin class's methods to `$teng` class
    and it calls $plugin\_class's init method if it has.

        $plugin_class->init($teng, $options);

    If you want to change imported method name, use `alias` option.
    for example:

        YourDB->load_plugin('BulkInsert', { alias => { bulk_insert => 'isnert_bulk' } });

    BulkInsert's "bulk\_insert" method is imported as "insert\_bulk".

- `$teng->handle_error`

    handling error method.

- `$teng->connected`

    check connected or not.

- `$teng->reconnect`

    reconnect database

- `$teng->mode`

    DEPRECATED AND \*WILL\* BE REMOVED. PLEASE USE ` no_ping ` option.

- How do you use display the profiling result?

    use [Devel::KYTProf](https://metacpan.org/pod/Devel%3A%3AKYTProf).

# TRIGGERS

Teng does not support triggers (NOTE: do not confuse it with SQL triggers - we're talking about Perl level triggers). If you really want to hook into the various methods, use something like [Moose](https://metacpan.org/pod/Moose), [Mouse](https://metacpan.org/pod/Mouse), and [Class::Method::Modifiers](https://metacpan.org/pod/Class%3A%3AMethod%3A%3AModifiers).

# SEE ALSO

## Fork

This module was forked from [DBIx::Skinny](https://metacpan.org/pod/DBIx%3A%3ASkinny), around version 0.0732.
many incompatible changes have been made.

# BUGS AND LIMITATIONS

No bugs have been reported.

# AUTHORS

Atsushi Kobayashi  `<nekokak __at__ gmail.com>`

Tokuhiro Matsuno <tokuhirom@gmail.com>

Daisuke Maki `<daisuke@endeworks.jp>`

# SUPPORT

    irc: #dbix-skinny@irc.perl.org

    ML: http://groups.google.com/group/dbix-skinny

# REPOSITORY

    git clone git://github.com/nekokak/p5-teng.git  

# LICENCE AND COPYRIGHT

Copyright (c) 2010, the Teng ["AUTHOR"](#author). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
