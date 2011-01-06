use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;

subtest 'do new' => sub {
    my $db = Mock::Basic->new({dbh => $dbh});
    isa_ok +$db->dbd, 'DBIx::Skin::DBD::SQLite';
};

done_testing;
