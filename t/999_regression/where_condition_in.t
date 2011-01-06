use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

use DBIx::Skinny::Profiler;
Mock::Basic->_attributes->{profiler} = DBIx::Skinny::Profiler->new;

subtest 'where condition in' => sub {
    Mock::Basic->search('mock_basic',{
        name => [],
    });
    is +Mock::Basic->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (1=0) :binds ';
    Mock::Basic->profiler->reset;

    Mock::Basic->search('mock_basic',{
        name => [qw/perl/],
    });
    is +Mock::Basic->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (name IN (?)) :binds perl';
    Mock::Basic->profiler->reset;

    Mock::Basic->search('mock_basic',{
        name => { in => [] },
    });
    is +Mock::Basic->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (1=0) :binds ';
    Mock::Basic->profiler->reset;

    Mock::Basic->search('mock_basic',{
        name => { in => [qw/perl/] },
    });
    is +Mock::Basic->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (name IN (?)) :binds perl';
    Mock::Basic->profiler->reset;

    Mock::Basic->search('mock_basic',{
        name => { 'not in' => [qw/perl/] },
    });
    is +Mock::Basic->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (name NOT IN (?)) :binds perl';
    Mock::Basic->profiler->reset;

    Mock::Basic->search('mock_basic',{
        name => { 'not in' => [] },
    });
    is +Mock::Basic->profiler->query_log->[0] , 'SELECT id, name, delete_fg FROM mock_basic WHERE (1=1) :binds ';
    Mock::Basic->profiler->reset;
};

done_testing;
