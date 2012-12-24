use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
$db_basic->setup_test_db;

subtest 'execute method' => sub {
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
    $db_basic->bulk_insert('mock_basic', $raw_data);

    my $data = [ map { +{ %$_, delete_fg => '0' } } @$raw_data ];

    {
        my $sth = $db_basic->execute('SELECT * FROM mock_basic');
        isa_ok $sth, 'DBI::st';
        is_deeply $sth->fetchall_arrayref(+{}), $data;
        is $sth->rows, 3;
        is $sth->{Statement}, 'SELECT * FROM mock_basic';
    }

    {
        local $ENV{TENG_SQL_COMMENT} = 1;
        my $sth = $db_basic->execute('SELECT * FROM mock_basic'); my ($file, $line) = (__FILE__, __LINE__);
        isa_ok $sth, 'DBI::st';
        is_deeply $sth->fetchall_arrayref(+{}), $data;
        is $sth->rows, 3;
        is $sth->{Statement}, "/* $file at line $line */\nSELECT * FROM mock_basic";
    }
};

subtest 'DEPRECATED' => sub {
    my $buffer = '';
    open my $fh, '>', \$buffer or die "Could not open in-memory buffer";
    *STDERR = $fh;

        $db_basic->_execute('SELECT * FROM mock_basic');

    close $fh;

    like $buffer, qr/IMPORTANT: '_execute' method is DEPRECATED AND \*WILL\* BE REMOVED\. PLEASE USE 'execute' method\./;
};

done_testing;

