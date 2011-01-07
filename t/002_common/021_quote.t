use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
$db->{profile} = 1;

subtest 'quote sql by sqlite' => sub {
    require DBIx::Skin::Profiler;
    local $db->{profiler} = DBIx::Skin::Profiler->new;
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    is +$db->profiler->query_log->[0] , 'INSERT INTO mock_basic (`name`, `id`) VALUES (?, ?) :binds perl, 1';
    $row->update({name => 'ruby'});
    is +$db->profiler->query_log->[1], 'UPDATE mock_basic SET `name` = ? WHERE (id = ?) :binds ruby, 1';
};

done_testing;

