use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);

subtest 'do new' => sub {
    isa_ok +Mock::Basic->dbd, 'DBIx::Skin::DBD::SQLite';
    my $db = Mock::Basic->new;
    isa_ok $db->dbd, 'DBIx::Skin::DBD::SQLite';
    isa_ok +Mock::Basic->dbd, 'DBIx::Skin::DBD::SQLite';
};

done_testing;
