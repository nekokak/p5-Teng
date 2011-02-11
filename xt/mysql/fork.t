use strict;
use Test::More;
use xt::Utils::mysql;
use t::Utils;
use Mock::Basic;
use Test::More;

subtest "fork, don't do anything, then see if the parent works" => sub {
    my $dbh = t::Utils->setup_dbh();
    my $db  = Mock::Basic->new( { dbh => $dbh } );
    $db->setup_test_db;

    my $pid = fork();
    if (! $pid) {
        undef $db;
        sleep 1;
        exit 0;
    } else {
        wait;
    }

    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'Mock::Basic::Row::MockBasic';
    is $row->name, 'perl';
};

done_testing;
