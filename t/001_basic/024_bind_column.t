use t::Utils;
use Test::More;
use Mock::BasicBindColumn;

my $dbh = t::Utils->setup_dbh;
Mock::BasicBindColumn->set_dbh($dbh);
Mock::BasicBindColumn->setup_test_db;

subtest 'insert data' => sub {
    local $SIG{__WARN__} = sub {};
    my $row = Mock::BasicBindColumn->insert('mock_basic_bind_column',{
        id   => 1,
        uid  => 1,
        name => 'name',
        body => 'body',
        raw  => 'raw',
    });

    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'name';
    is $row->body, 'body';
    is $row->raw,  'raw';

    $row->update({id => 2, name => 'name2', body => 'body2', raw => 'raw2'});

    ok $row->delete();

    ok not +Mock::BasicBindColumn->single('mock_basic_bind_column');

    $row = Mock::BasicBindColumn->insert('mock_basic_bind_column',{
        id   => 3,
        uid  => 3,
        name => 'name3',
        body => 'body3',
        raw  => 'raw3',
    });

    Mock::BasicBindColumn->update(
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

    $row = Mock::BasicBindColumn->single('mock_basic_bind_column');
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id,   4;
    is $row->uid,  4;
    is $row->name, 'name4';
    is $row->body, 'body4';
    is $row->raw,  'raw4';

    Mock::BasicBindColumn->update_by_sql(
        'update mock_basic_bind_column set id = ?, uid = ?, name = ?, body = ? , raw = ?', [5, 5, 'name5', 'body5', 'raw5']
    );

    $row = Mock::BasicBindColumn->search('mock_basic_bind_column')->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id,   5;
    is $row->uid,  5;
    is $row->name, 'name5';
    is $row->body, 'body5';
    is $row->raw,  'raw5';

    ok +Mock::BasicBindColumn->delete(
        'mock_basic_bind_column' => +{
            id => 5,
        }
    );
 
    ok not +Mock::BasicBindColumn->search_by_sql('select * from mock_basic_bind_column where id = ?',[5])->first;

    ok +Mock::BasicBindColumn->insert('mock_basic_bind_column',{
        id   => 6,
        uid  => 6,
        name => 'name6',
        body => 'body6',
        raw  => 'raw6',
    });

    ok +Mock::BasicBindColumn->delete_by_sql('delete from mock_basic_bind_column where id = ?',[6]);

    ok not +Mock::BasicBindColumn->search_by_sql('select * from mock_basic_bind_column where id = ?',[4])->first;
};

done_testing;

