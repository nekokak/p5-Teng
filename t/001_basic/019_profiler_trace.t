use t::Utils;
use Test::More;

my $content;
BEGIN {
    $ENV{SKINNY_TRACE} = 1;
    open my $fh, '>', \$content; 
    *STDERR = $fh;
}

use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

is $content , qq{CREATE TABLE mock_basic ( id integer, name text, delete_fg int(1) default 0, primary key ( id ) )\n};

Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});
is $content, qq{CREATE TABLE mock_basic ( id integer, name text, delete_fg int(1) default 0, primary key ( id ) )\nINSERT INTO mock_basic (`name`, `id`) VALUES (?, ?) :binds perl, 1\n};

done_testing;

