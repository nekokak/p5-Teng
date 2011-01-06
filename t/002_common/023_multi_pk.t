use t::Utils;
use Test::More;

{
    package Mock::MultiPK;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };

    sub setup_test_db {
        my $self = shift;

        for my $table ( qw( a_multi_pk_table c_multi_pk_table ) ) {
            $self->do(qq{
                DROP TABLE IF EXISTS $table
            });
        }

        {
            $self->do(q{
                CREATE TABLE a_multi_pk_table (
                    id_a  integer,
                    id_b  integer,
                    memo  integer default 'foobar',
                    primary key( id_a, id_b )
                )
            });
            $self->do(q{
                CREATE TABLE c_multi_pk_table (
                    id_c  integer,
                    id_d  integer,
                    memo  integer default 'foobar',
                    primary key( id_c, id_d )
                )
            });
        }
    }

    package Mock::MultiPK::Schema;
    use utf8;
    use DBIx::Skinny::Schema;

    install_table 'a_multi_pk_table' => schema {
        pk [ qw( id_a id_b ) ];
        columns qw( id_a id_b memo );
    };

    install_table 'c_multi_pk_table' => schema {
        pk qw( id_c id_d );
        columns qw( id_c id_d memo );
    };
}

my $skinny = Mock::MultiPK->new;

{
    subtest 'init data' => sub {
        $skinny->setup_test_db;

        $skinny->insert( 'a_multi_pk_table', { id_a => 1, id_b => 1 } );
        $skinny->insert( 'a_multi_pk_table', { id_a => 1, id_b => 2 } );
        $skinny->insert( 'a_multi_pk_table', { id_a => 1, id_b => 3 } );
        my $data = $skinny->insert( 'a_multi_pk_table', { id_a => 2, id_b => 1 } );
        $skinny->insert( 'a_multi_pk_table', { id_a => 2, id_b => 2 } );

        is( $data->id_a, 2 );
        is( $data->id_b, 1 );

        $skinny->insert( 'a_multi_pk_table', { id_a => 3, id_b => 10 } );
        $skinny->insert( 'a_multi_pk_table', { id_a => 3, id_b => 20 } );
        $skinny->insert( 'a_multi_pk_table', { id_a => 3, id_b => 30 } );
    };

    my ( $itr, $a_multi_pk_table );

    subtest 'multi pk search' => sub {
        $itr = $skinny->search( 'a_multi_pk_table', { id_a => 1 } );
        is( $itr->count, 3, 'first - user has 3 books' );

        $a_multi_pk_table = $skinny->single( 'a_multi_pk_table', { id_a => 1, id_b => 3 } );
        ok( $a_multi_pk_table );
        is( $a_multi_pk_table->memo, 'foobar' );
        $a_multi_pk_table->update( { memo => 'hoge' } );

        $a_multi_pk_table = $skinny->single( 'a_multi_pk_table', { id_a => 1, id_b => 3 } );
        is( $a_multi_pk_table->memo, 'hoge', 'update' );

        $a_multi_pk_table->delete;

        $itr = $skinny->search( 'a_multi_pk_table', { id_a => 1 } );
        is( $itr->count, 2, 'delete and user has 2 books' );
        ok ( not $skinny->single( 'a_multi_pk_table', { id_a => 1, id_b => 3 } ) );

        $a_multi_pk_table = $skinny->search( 'a_multi_pk_table', { id_a => 1 } )->first;
        ok( $a_multi_pk_table );

        my ( $id_a, $id_b ) = ( $a_multi_pk_table->id_a, $a_multi_pk_table->id_b );

        $a_multi_pk_table->delete;

        ok ( not $skinny->single( 'a_multi_pk_table', { id_a => $id_a, id_b => $id_b } ) );
    };

    subtest 'multi pk search_by_sql' => sub {
        my ( $itr, $row );

        $itr = $skinny->search_by_sql(q{SELECT * FROM a_multi_pk_table WHERE id_a = ? AND id_b = ?}, [3, 10], 'a_multi_pk_table');

        is( $itr->count, 1 );

        $row = $itr->first;
        is( $row->memo, 'foobar' );
        $row->update( { memo => 'hoge' } );

        $row = $skinny->search_by_sql(q{SELECT * FROM a_multi_pk_table WHERE id_a = ? AND id_b = ?}, [3, 10])->first;

        is( $row->memo, 'hoge' );
    };

    subtest 'multi pk row insert' => sub {
        my ( $rs, $itr, $row );

        $row = $skinny->insert( 'a_multi_pk_table', { id_a => 3, id_b => 40 } );

        is_deeply( $row->get_columns, { id_a => 3, id_b => 40 } );

        $row->insert(); # find_or_create => find

        $itr = $skinny->search( 'a_multi_pk_table', { id_a => 3 } );
        is( $itr->count, 4 );

        $row->delete();

        $itr = $skinny->search( 'a_multi_pk_table', { id_a => 3 } );
        is( $itr->count, 3 );
    };
}

{
    subtest 'init data' => sub {
        $skinny->setup_test_db;

        $skinny->insert( 'c_multi_pk_table', { id_c => 1, id_d => 1 } );
        $skinny->insert( 'c_multi_pk_table', { id_c => 1, id_d => 2 } );
        $skinny->insert( 'c_multi_pk_table', { id_c => 1, id_d => 3 } );
        my $data = $skinny->insert( 'c_multi_pk_table', { id_c => 2, id_d => 1 } );
        $skinny->insert( 'c_multi_pk_table', { id_c => 2, id_d => 2 } );

        is( $data->id_c, 2 );
        is( $data->id_d, 1 );

        $skinny->insert( 'c_multi_pk_table', { id_c => 3, id_d => 10 } );
        $skinny->insert( 'c_multi_pk_table', { id_c => 3, id_d => 20 } );
        $skinny->insert( 'c_multi_pk_table', { id_c => 3, id_d => 30 } );
    };

    my ( $itr, $a_multi_pk_table );

    subtest 'multi pk search' => sub {
        $itr = $skinny->search( 'c_multi_pk_table', { id_c => 1 } );
        is( $itr->count, 3, 'first - user has 3 books' );

        $a_multi_pk_table = $skinny->single( 'c_multi_pk_table', { id_c => 1, id_d => 3 } );
        ok( $a_multi_pk_table );
        is( $a_multi_pk_table->memo, 'foobar' );
        $a_multi_pk_table->update( { memo => 'hoge' } );

        $a_multi_pk_table = $skinny->single( 'c_multi_pk_table', { id_c => 1, id_d => 3 } );
        is( $a_multi_pk_table->memo, 'hoge', 'update' );

        $a_multi_pk_table->delete;

        $itr = $skinny->search( 'c_multi_pk_table', { id_c => 1 } );
        is( $itr->count, 2, 'delete and user has 2 books' );
        ok ( not $skinny->single( 'c_multi_pk_table', { id_c => 1, id_d => 3 } ) );

        $a_multi_pk_table = $skinny->search( 'c_multi_pk_table', { id_c => 1 } )->first;
        ok( $a_multi_pk_table );

        my ( $id_c, $id_d ) = ( $a_multi_pk_table->id_c, $a_multi_pk_table->id_d );

        $a_multi_pk_table->delete;

        ok ( not $skinny->single( 'c_multi_pk_table', { id_c => $id_c, id_d => $id_d } ) );
    };

    subtest 'multi pk search_by_sql' => sub {
        my ( $itr, $row );

        $itr = $skinny->search_by_sql(q{SELECT * FROM c_multi_pk_table WHERE id_c = ? AND id_d = ?}, [3, 10], 'c_multi_pk_table');

        is( $itr->count, 1 );

        $row = $itr->first;
        is( $row->memo, 'foobar' );
        $row->update( { memo => 'hoge' } );

        $row = $skinny->search_by_sql(q{SELECT * FROM c_multi_pk_table WHERE id_c = ? AND id_d = ?}, [3, 10])->first;

        is( $row->memo, 'hoge' );
    };

    subtest 'multi pk row insert' => sub {
        my ( $rs, $itr, $row );

        $row = $skinny->insert( 'c_multi_pk_table', { id_c => 3, id_d => 40 } );

        is_deeply( $row->get_columns, { id_c => 3, id_d => 40 } );

        $row->insert(); # find_or_create => find

        $itr = $skinny->search( 'c_multi_pk_table', { id_c => 3 } );
        is( $itr->count, 4 );

        $row->delete();

        $itr = $skinny->search( 'c_multi_pk_table', { id_c => 3 } );
        is( $itr->count, 3 );
    };

    subtest 'multi pk find_or_create' => sub {
        my ( $rs, $itr, $row );

        {
            my $row = $skinny->find_or_create('c_multi_pk_table' => {id_c => 50, id_d => 90});
            $row->update({memo => 'yay'});
            is_deeply( $row->get_columns, { id_c => 50, id_d => 90, memo => 'yay' } );
        }

        {
            my $row = $skinny->find_or_create('c_multi_pk_table' => {id_c => 50, id_d => 90});
            is_deeply( $row->get_columns, { id_c => 50, id_d => 90, memo => 'yay' } );
        }
    };
}

done_testing;

