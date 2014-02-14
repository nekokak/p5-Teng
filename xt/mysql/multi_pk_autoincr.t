use xt::Utils::mysql;
use Test::More;

{
    package Mock::MultiPK;
    use parent 'Teng';

    sub setup_test_db {
        my $self = shift;

        for my $table ( qw( multi_pk_table ) ) {
            $self->do(qq{
                DROP TABLE IF EXISTS $table
            });
        }

        {
            $self->do(q{
                CREATE TABLE multi_pk_table (
                    id         INTEGER AUTO_INCREMENT,
                    created_at DATETIME,
                    memo       VARCHAR(255) NOT NULL DEFAULT 'foobar',
                    PRIMARY KEY( id, created_at )
                )
            });
        }
    }

    package Mock::MultiPK::Schema;
    use utf8;
    use Teng::Schema::Declare;

    table {
        name 'multi_pk_table';
        pk qw( id created_at );
        columns qw( id created_at memo );
    };
}

my $dbh = t::Utils->setup_dbh;
my $db = Mock::MultiPK->new({dbh => $dbh});
$db->setup_test_db;

my $row = $db->insert('multi_pk_table', {
    created_at => '2000-11-11',
    memo       => 'blah',
});

isa_ok $row, 'Mock::MultiPK::Row::MultiPkTable';
ok $row->id;
is $row->memo, 'blah';

done_testing;
