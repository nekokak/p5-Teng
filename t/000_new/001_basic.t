use strict;
use Test::More;
use t::Utils;

use_ok "Mock::Basic";

subtest 'basic' => sub {
    my $db = Mock::Basic->new(
        connect_info => [ "dbi:SQLite::memory:" ],
    );

    ok $db->dbh, "dbh is now defined";
    t::Utils::prepare_db( "Mock::Basic", $db->dbh );

    my $name = join '.', time(), rand(), $$, {};
    my $row = $db->insert( mock_basic => {
        id => 1,
        name => $name,
        delete_fg => 0,
    } );
    ok $row, "inserted row is defined";
    isa_ok $row, "Mock::Basic::Row::MockBasic";
    isa_ok $row, "DBIx::Skin::Row";

    my $sth = $db->dbh->prepare( "SELECT * FROM mock_basic WHERE id = ?" );
    $sth->execute(1);
    my $hash = $sth->fetchrow_hashref;
    is $hash->{id}, $row->id, "id matches";
    is $hash->{name}, $row->name, "name matches";
    is $hash->{delete_fg}, $row->delete_fg, "delete_fg matches";
};

done_testing;
