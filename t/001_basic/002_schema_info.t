use t::Utils;
use Mock::Basic;
use Mock::BasicBindColumn;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'schema info' => sub {
    is +$db->schema, 'Mock::Basic::Schema';

    my $info = Mock::Basic->schema->schema_info;
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
    is +Mock::BasicBindColumn->schema, 'Mock::BasicBindColumn::Schema';

    my $info = Mock::BasicBindColumn->schema->schema_info;
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
