use t::Utils;
use Mock::Basic;
use Test::More;

my $db = Mock::Basic->new(
    connect_info => [ 'dbi:SQLite:', '', '' ]
);

my $connect_info = $db->connect_info();

is_deeply $connect_info, [ 'dbi:SQLite:', '', '', { RaiseError => 1, AutoCommit => 1, PrintError => 0 } ];

done_testing;
