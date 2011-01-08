use t::Utils;
use Mock::Basic;
use Test::More;

TODO: {
todo_skip 'not yet...',0;
my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

{
    my $hash = +{
        id   => 1,
        name => 'perl',
    };

    my $row = $db->hash_to_row('mock_basic', $hash);
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->id, 1;
    is $row->name, 'perl';

    $row->insert;
}

{
    my $row = $db->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skin::Row';
    is $row->id, 1;
    is $row->name, 'perl';
}

done_testing;
}
