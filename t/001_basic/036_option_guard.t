use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest '' => sub {
    is $db->no_ping, 0, "no_ping is not set";
    {
        my $guard = $db->option_guard(no_ping => 1);
        is $db->no_ping, 1, "no_ping is set";
    }
    is $db->no_ping, 0, "no_ping is not set";
};

done_testing();
