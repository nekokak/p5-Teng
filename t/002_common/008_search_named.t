use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});
$db->insert('mock_basic',{
    id   => 2,
    name => 'ruby',
});

subtest 'search_named' => sub {
    my $itr = $db->search_named(q{SELECT * FROM mock_basic WHERE id = :id}, {id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id , 1;
    is $row->name, 'perl';
};

subtest 'search_named' => sub {
    my $itr = $db->search_named(q{SELECT * FROM mock_basic WHERE id = :id OR name = :name}, {id => 1, name => 'ruby'});
    isa_ok $itr, 'Teng::Iterator';

    my @row = $itr->all;
    isa_ok $row[0], 'Teng::Row';
    is $row[0]->id , 1;
    is $row[0]->name, 'perl';
    isa_ok $row[1], 'Teng::Row';
    is $row[1]->id , 2;
    is $row[1]->name, 'ruby';
};

subtest 'search_named with arrayref' => sub {

    my $org_code = Teng->can('search_by_sql');
    my ($query, $bind);
    no warnings 'redefine';
    local *Teng::search_by_sql = sub {
        $query = $_[1];
        $bind  = $_[2];
        $org_code->(@_);
    };

    my $itr = $db->search_named(q{
        SELECT * FROM mock_basic
        WHERE (
            id IN :ids
        )
        limit 100
    }, +{ ids => [1, 2, 3] });

    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';
    is $row->id , 1;
    is $row->name, 'perl';

    is $query, q{
        SELECT * FROM mock_basic
        WHERE (
            id IN ( ?,?,? )
        )
        limit 100
    };
    is_deeply $bind, [qw/1 2 3/];
};

subtest 'search_named with non existent bind' => sub {
    eval {
        my $itr = $db->search_named(
            q{SELECT * FROM mock_basic WHERE id = :id OR name = :name},
            { id => 1 }
        );
    };
    like $@, qr/'name' does not exist in bind hash/;
};

done_testing;
