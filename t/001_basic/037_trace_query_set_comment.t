use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;

subtest 'trace_query_set_comment method' => sub {
    local $ENV{TENG_SQL_COMMENT} = 1;

    subtest 'SQL_COMMENT_LEVEL = 1 (default)' => sub {
        my $sth = $db_basic->execute('SELECT * FROM mock_basic'); my ($file, $line) = (__FILE__, __LINE__);
        is $sth->{Statement}, "/* $file at line $line */\nSELECT * FROM mock_basic";
    };

    subtest 'SQL_COMMENT_LEVEL = 2' => sub {
        local $Teng::SQL_COMMENT_LEVEL = 2;
        my $func = sub { $db_basic->execute('SELECT * FROM mock_basic') };
        my $sth = $func->(); my ($file, $line) = (__FILE__, __LINE__);
        is $sth->{Statement}, "/* $file at line $line */\nSELECT * FROM mock_basic";
    };

    subtest 'trace_ignore_if' => sub {
        my $called = 0;
        $db_basic->trace_ignore_if(sub {
            my (undef, $file, $line) = @_;
            $called++;
            return $file eq __FILE__ && $line == __LINE__+3;
        });

        my $func = sub { $db_basic->execute('SELECT * FROM mock_basic') }; # ignore this line
        my $sth = $func->(); my ($file, $line) = (__FILE__, __LINE__);
        is $sth->{Statement}, "/* $file at line $line */\nSELECT * FROM mock_basic";
        is $called, 2;
    };
};

done_testing;
