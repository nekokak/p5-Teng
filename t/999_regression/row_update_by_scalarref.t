use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'delete/update rows arrayref' => sub {
    Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 1,
    });
    my $row = Mock::Basic->single('mock_basic', {id => 1});
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
