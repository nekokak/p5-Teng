use strict;
use warnings;
use t::Utils;
use Test::More;

{
    package Mock::BasicALLINONE;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
        connect_options => { AutoCommit => 1 },
    };

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_basic (
                id   integer,
                name text,
                delete_fg int(1) default 0,
                primary key ( id )
            )
        });
    }
}

{
    package Mock::BasicALLINONE::Schema;
    use utf8;
    use DBIx::Skinny::Schema;

    install_table mock_basic => schema {
        pk 'id';
        columns qw/
            id
            name
            delete_fg
        /;
    };
}

{
    package Mock::BasicALLINONE::Row::MockBasic;
    use strict;
    use warnings;
    use base 'DBIx::Skinny::Row';
}

Mock::BasicALLINONE->setup_test_db;
Mock::BasicALLINONE->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

my $itr = Mock::BasicALLINONE->search_by_sql(q{SELECT * FROM mock_basic WHERE id = ?}, [1]);
isa_ok $itr, 'DBIx::Skinny::Iterator';

my $row = $itr->first;
isa_ok $row, 'Mock::BasicALLINONE::Row::MockBasic';
is $row->id , 1;
is $row->name, 'perl';

done_testing;

