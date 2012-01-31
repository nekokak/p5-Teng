{
    package Mock::LoadPlugin;
    use strict;
    use warnings;
    use parent qw/Teng/;
    use Class::Method::Modifiers;

    __PACKAGE__->load_plugin('Count');

    around qw/count/ => sub {
        my $code = shift;
        my $count = $code->(@_);
        return $count + 1;
    };

    sub setup_test_db {
        my $self = shift;
        $self->do(q{
            CREATE TABLE mock_table(
                id INTEGER PRIMARY KEY,
                name TEXT
            )
        });
    }
    package Mock::LoadPlugin::Schema;
    use utf8;
    use Teng::Schema::Declare;

    table {
        name 'mock_table';
        pk qw( id );
        columns qw( id name );
    };
    package Mock::LoadPlugin2;
    use strict;
    use warnings;
    use parent qw/Teng/;

    __PACKAGE__->load_plugin('Count');
    package Mock::LoadPlugin2::Schema;
    use utf8;
    use Teng::Schema::Declare;

    table {
        name 'mock_table';
        pk qw( id );
        columns qw( id name );
    };

}
use strict;
use warnings;
use t::Utils;
use Test::More;

use DBI;
use Teng::Schema::Loader;
use MyGuard;

my $db_file = __FILE__;
$db_file =~ s/\.t$/.db/;
unlink $db_file if -f $db_file;
my $guard = MyGuard->new(sub { unlink $db_file });

my $dbh = DBI->connect("dbi:SQLite:$db_file",'','',{});

my $db = Mock::LoadPlugin->new(dbh => $dbh);
my $db2 = Mock::LoadPlugin2->new(dbh => $dbh);
$db->setup_test_db;

is $db2->count('mock_table' => 'id', {}) => 0, 'is empty table';
is $db->count('mock_table' => 'id', {}) => ($db2->count('mock_table' => 'id', {}) + 1), 'Class::Method::Modifiers trigger only apply Mock::LoadPlugin';

done_testing;
