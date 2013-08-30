use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;

subtest 'data2row method' => sub {
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

    my $rows = [ map { $db_basic->data2row(mock_basic => $_) } @$raw_data ];
    isa_ok $_, 'Teng::Row' for @$rows;
    is $rows->[0]->id, 1;
    is $rows->[1]->id, 2;
    is $rows->[2]->id, 3;
};

done_testing;

