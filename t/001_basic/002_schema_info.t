use t::Utils;
use Test::More;

plan skip_all => 'schema_info has been deprecated.';

use Mock::Basic;
use Mock::BasicBindColumn;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'schema info' => sub {
    is +$db->schema, 'Mock::Basic::Schema';

    my $info = $db->schema->schema_info;
    is_deeply $info,{
        mock_basic => {
            pk      => 'id',
            columns => [
                'id',
                'name',
                'delete_fg',
            ],
            row_class    => 'Mock::Basic::Row::MockBasic',
            column_types => +{},
        }
    };

    isa_ok +$db->dbh, 'DBI::db';
    done_testing;
};

subtest 'schema info' => sub {
    my $db_basic_bind_column = +Mock::BasicBindColumn->new({dbh => $dbh});
    is +$db_basic_bind_column->schema, 'Mock::BasicBindColumn::Schema';

    my $info = $db_basic_bind_column->schema->schema_info;
    is_deeply $info,{
        mock_basic_bind_column => {
            pk      => 'id',
            columns => [
                'id',
                'uid',
                'name',
                'body',
                'raw',
            ],
            column_types => +{
                body => 'blob',
                uid  => 'bigint',
                raw  => 'bin',
            },
            row_class => 'Mock::BasicBindColumn::Row::MockBasicBindColumn',
        }
    };

    done_testing;
};

done_testing;
