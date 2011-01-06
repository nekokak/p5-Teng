use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

use DBIx::Skin::Profiler;
$db->_attributes->{profiler} = DBIx::Skin::Profiler->new;

subtest 'where condition in' => sub {
    $db->search('mock_basic',{
        name => [],
    });
    is +$db->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (1=0) :binds ';
    $db->profiler->reset;

    $db->search('mock_basic',{
        name => [qw/perl/],
    });
    is +$db->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (name IN (?)) :binds perl';
    $db->profiler->reset;

    $db->search('mock_basic',{
        name => { in => [] },
    });
    is +$db->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (1=0) :binds ';
    $db->profiler->reset;

    $db->search('mock_basic',{
        name => { in => [qw/perl/] },
    });
    is +$db->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (name IN (?)) :binds perl';
    $db->profiler->reset;

    $db->search('mock_basic',{
        name => { 'not in' => [qw/perl/] },
    });
    is +$db->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (name NOT IN (?)) :binds perl';
    $db->profiler->reset;

    $db->search('mock_basic',{
        name => { 'not in' => [] },
    });
    is +$db->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (1=1) :binds ';
    $db->profiler->reset;
};

done_testing;
