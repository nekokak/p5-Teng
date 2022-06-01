use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;

subtest 'new_row_from_hash method' => sub {
    my $raw_data = [
        {
            id   => 1,
            name => 'perl',
        },
        {
            id   => 2,
            name => 'ruby',
        },
        {
            id   => 3,
            name => 'python',
        },
    ];

    my $rows = [ map { $db_basic->new_row_from_hash(mock_basic => $_) } @$raw_data ];
    is $rows->[0]->{sql}, sprintf('/* DUMMY QUERY Mock::Basic->new_row_from_hash created from %s line %d */', __FILE__, __LINE__ - 1);
    isa_ok $_, 'Teng::Row' for @$rows;
    is $rows->[0]->id, 1;
    is $rows->[1]->id, 2;
    is $rows->[2]->id, 3;

    subtest 'with sql' => sub {
        my $sql = 'SELECT * FROM mock_basic WHERE id = 1';
        is $db_basic->new_row_from_hash(mock_basic => $raw_data->[0], $sql)->{sql}, $sql;
    };
};

done_testing;

