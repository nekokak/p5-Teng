use t::Utils;
use Test::More;
use Mock::Basic;
use Test::Mock::Guard qw/mock_guard/;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'reconnect_with_clone_exception' => sub {
    {
        my $guard; $guard = mock_guard('DBI::db' => +{clone => sub { die('exception') } });
        ok !eval {
            $db->reconnect;
            1;
        };
    }
    ok eval {
        $db->reconnect;
        1;
    };
};

done_testing;
