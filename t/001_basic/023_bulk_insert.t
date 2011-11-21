use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;

subtest 'bulk_insert method' => sub {
    $db_basic->bulk_insert('mock_basic',[
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
    ]);
    is +$db_basic->count('mock_basic', 'id'), 3;
};

subtest 'DEPRECATED' => sub {
    my $buffer = '';
    open my $fh, '>', \$buffer or die "Could not open in-memory buffer";
    *STDERR = $fh;

        Mock::Basic->load_plugin('BulkInsert');

    close $fh;

    like $buffer, qr/IMPORTANT: Teng::Plugin::BulkInsert is DEPRECATED AND \*WILL\* BE REMOVED\. DO NOT USE\./;
};

done_testing;

