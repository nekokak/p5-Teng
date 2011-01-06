use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'do raise error' => sub {
    eval {
        $db->do(q{select * from hoge});
    };
    ok $@;
};

subtest 'do with bind' => sub {
    eval {
        $db->do(q{SELECT * from mock_basic WHERE name = ?}, undef, "hoge")
    };
    ok not $@;
};

done_testing;

