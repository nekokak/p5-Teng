use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'do raise error' => sub {
    eval {
        Mock::Basic->do(q{select * from hoge});
    };
    ok $@;
};

subtest 'do with bind' => sub {
    eval {
        Mock::Basic->do(q{SELECT * from mock_basic WHERE name = ?}, undef, "hoge")
    };
    ok not $@;
};

done_testing;

