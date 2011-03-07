use t::Utils;
use Test::More;
use Mock::BasicBindColumn;
use DBI qw/:sql_types/;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::BasicBindColumn->new({dbh => $dbh});
$db->setup_test_db;

subtest 'schema information' => sub {
    my $table = $db->schema->get_table( 'mock_basic_bind_column' );
    ok $table, "got table";

    ok ! $table->get_sql_type( 'id' ), "no sqltype info for column 'id'";
    is $table->get_sql_type('uid'), SQL_BIGINT;

    ok ! $table->get_sql_type( 'name' ), "no sqltype info for column 'name'";

    is $table->get_sql_type('body'), SQL_BLOB;
    is $table->get_sql_type('raw'), SQL_BLOB;
};

TODO : {
  todo_skip 'no not yet...',0;
# XXX 2011/01/08 19:40 時点でsqltypesをSchema::Tableに格納するように
# 変更したが、まだsqltype自体を使用してないのにこのテストは通ってしまった！
# sqltypesのテストとして機能してないのでは？？？
subtest 'insert data' => sub {
    local $SIG{__WARN__} = sub {}; # <- why need this?? -- tokuhirom@20100106
    my $row = $db->insert('mock_basic_bind_column',{
        id   => 1,
        uid  => 1,
        name => 'name',
        body => 'body',
        raw  => 'raw',
    });


    isa_ok $row, 'Teng::Row';
    is $row->name, 'name';
    is $row->body, 'body';
    is $row->raw,  'raw';

    $row->update({id => 2, name => 'name2', body => 'body2', raw => 'raw2'});

    ok $row->delete();

    ok not +$db->single('mock_basic_bind_column');

    $row = $db->insert('mock_basic_bind_column',{
        id   => 3,
        uid  => 3,
        name => 'name3',
        body => 'body3',
        raw  => 'raw3',
    });

    $db->update(
        'mock_basic_bind_column' => +{
            id   => 4,
            uid  => 4,
            name => 'name4',
            body => 'body4',
            raw  => 'raw4',
        },{
            id => 3,
        }
    );

    $row = $db->single('mock_basic_bind_column');
    isa_ok $row, 'Teng::Row';
    is $row->id,   4;
    is $row->uid,  4;
    is $row->name, 'name4';
    is $row->body, 'body4';
    is $row->raw,  'raw4';

    $db->do(
        'update mock_basic_bind_column set id = ?, uid = ?, name = ?, body = ? , raw = ?', {}, 5, 5, 'name5', 'body5', 'raw5'
    );

    $row = $db->search('mock_basic_bind_column')->next;
    isa_ok $row, 'Teng::Row';
    is $row->id,   5;
    is $row->uid,  5;
    is $row->name, 'name5';
    is $row->body, 'body5';
    is $row->raw,  'raw5';

    ok +$db->delete(
        'mock_basic_bind_column' => +{
            id => 5,
        }
    );
 
    ok not +$db->search_by_sql('select * from mock_basic_bind_column where id = ?',[5])->next;

    ok +$db->insert('mock_basic_bind_column',{
        id   => 6,
        uid  => 6,
        name => 'name6',
        body => 'body6',
        raw  => 'raw6',
    });

    ok +$db->do('delete from mock_basic_bind_column where id = ?',{}, 6);

    ok not +$db->search_by_sql('select * from mock_basic_bind_column where id = ?',[4])->next;
};
};

done_testing;
