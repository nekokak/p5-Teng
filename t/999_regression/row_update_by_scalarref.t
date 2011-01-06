use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'delete/update rows arrayref' => sub {
    $db->insert('mock_basic',{
        id   => 1,
        name => 1,
    });
    my $row = $db->single('mock_basic', {id => 1});
    is $row->name, 1;

    my $msg;
    {
        local $SIG{__WARN__} = sub {
            $msg = $_[0];
        };
        $row->update({name => \'name + 1'});

        is $row->name, 1;
    }
    like $msg, qr/name's row data is untrusted. by your update query./;
};

done_testing;
