use strict;
use warnings;
use t::Utils;
use Test::More;

{
    package Mock::BasicALLINONE;
    use parent 'Teng';

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
    use Teng::Schema::Declare;
    schema {
        table {
            name 'mock_basic';
            pk 'id';
            columns qw/
                id
                name
                delete_fg
            /;
        };
    };
}

{
    package Mock::BasicALLINONE::Row::MockBasic;
    use strict;
    use warnings;
    use base 'Teng::Row';
}

my $db = Mock::BasicALLINONE->new(connect_info => ['dbi:SQLite::memory:', '','']);

$db->setup_test_db;
$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

my $itr = $db->search_by_sql(q{SELECT * FROM mock_basic WHERE id = ?}, [1]);
isa_ok $itr, 'Teng::Iterator';

my $row = $itr->next;
isa_ok $row, 'Mock::BasicALLINONE::Row::MockBasic';
is $row->id , 1;
is $row->name, 'perl';

done_testing;

