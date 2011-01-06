use t::Utils;
use Mock::Basic;
use Test::More;
use Encode ();

{
    package Mock::UTF8;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_utf8 (
                id   INT,
                name TEXT
            )
        });
    }
    package Mock::UTF8::Schema;
    use DBIx::Skinny::Schema;

    install_table mock_utf8 => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    install_utf8_columns qw/name/;
}

Mock::UTF8->setup_test_db;
my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'insert mock_utf8 data' => sub {
    my $row = Mock::UTF8->insert('mock_utf8',{
        id   => 1,
        name => 'ぱーる',
    });

    isa_ok $row, 'DBIx::Skinny::Row';
    ok utf8::is_utf8($row->name);
    is $row->name, 'ぱーる';
};

subtest 'update mock_utf8 data' => sub {
    ok +Mock::UTF8->update('mock_utf8',{name => 'るびー'},{id => 1});
    my $row = Mock::UTF8->single('mock_utf8',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';
    ok utf8::is_utf8($row->name);
    is $row->name, 'るびー';
};

subtest 'mock_basic data should not enable utf8 flag' => sub {
    ok +Mock::Basic->insert('mock_basic',{name => 'るびー'},{id => 1});
    my $row = Mock::Basic->single('mock_basic',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';
    ok !utf8::is_utf8($row->name);
    is $row->name, Encode::encode_utf8('るびー');
};

done_testing;
