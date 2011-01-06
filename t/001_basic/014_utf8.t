use t::Utils;
use Mock::Basic;
use Test::More;
use Encode ();

{
    package Mock::UTF8;
    use DBIx::Skin;

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_utf8 (
                id   INT,
                name TEXT
            )
        });
    }
    package Mock::UTF8::Schema;
    use DBIx::Skin::Schema;

    install_table mock_utf8 => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    install_utf8_columns qw/name/;
}

my $utf8_db = Mock::UTF8->new(
    +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    }
);
$utf8_db->setup_test_db;

my $dbh = t::Utils->setup_dbh;
my $basic_db = Mock::Basic->new(+{dbh => $dbh});
   $basic_db->setup_test_db;

subtest 'insert mock_utf8 data' => sub {
    my $row = $utf8_db->insert('mock_utf8',{
        id   => 1,
        name => 'ぱーる',
    });

    isa_ok $row, 'DBIx::Skin::Row';
    ok utf8::is_utf8($row->name);
    is $row->name, 'ぱーる';
};

subtest 'update mock_utf8 data' => sub {
    ok +$utf8_db->update('mock_utf8',{name => 'るびー'},{id => 1});
    my $row = $utf8_db->single('mock_utf8',{id => 1});

    isa_ok $row, 'DBIx::Skin::Row';
    ok utf8::is_utf8($row->name);
    is $row->name, 'るびー';
};

subtest 'mock_basic data should not enable utf8 flag' => sub {
    ok +$basic_db->insert('mock_basic',{name => 'るびー'},{id => 1});
    my $row = $basic_db->single('mock_basic',{id => 1});

    isa_ok $row, 'DBIx::Skin::Row';
    ok !utf8::is_utf8($row->name);
    is $row->name, Encode::encode_utf8('るびー');
};

done_testing;
