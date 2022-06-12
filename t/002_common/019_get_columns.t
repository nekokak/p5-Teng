use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'get_columns' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'Teng::Row';

    my $data = $row->get_columns;
    ok $data;
    is $data->{id}, 1;
    is $data->{name}, 'perl';
};

subtest 'get_columns multi line' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 2,
        name => 'ruby',
    });
    isa_ok $row, 'Teng::Row';

    my $data = [map {$_->get_columns} $db->search('mock_basic')->all];
    is_deeply $data, [
        {
            name => 'perl',
            id   => 1,
            delete_fg => 0,
        },
        {
            name => 'ruby',
            id   => 2,
            delete_fg => 0,
        }
    ];
};

done_testing;

