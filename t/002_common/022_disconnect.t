use t::Utils;
use Mock::Basic;
use Test::More;

use File::Temp qw(tempdir);
my $tempdir = tempdir(CLEANUP => 1);
my $file    = File::Spec->catfile($tempdir, 'disconnect.db');

my $dbh = t::Utils->setup_dbh($file);
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'insert mock_basic data/ insert method' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'perl';
};

subtest 'disconnect' => sub {
    Mock::Basic->disconnect();
    ok ! defined Mock::Basic->_attributes->{dbh}, "dbh is undef";
};

subtest 'insert after disconnect trigger a connect' => sub {
    Mock::Basic->set_dbh(t::Utils->setup_dbh($file));
    my $row = Mock::Basic->create('mock_basic',{
        id   => 2,
        name => 'ruby',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'ruby';
};

done_testing;
