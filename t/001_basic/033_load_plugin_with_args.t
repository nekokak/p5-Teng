use FindBin;
use lib "$FindBin::Bin/../lib";
use t::Utils;
use Test::More;

BEGIN { use_ok( 'Mock::Basic' ); }

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

(ref $db)->load_plugin('ArgsTest');

ok defined &Mock::Basic::args_class;
ok defined &Mock::Basic::args_opt;

is $db->args_class, ref $db;

# unload plugin class;
undef &Mock::Basic::args_class;
undef &Mock::Basic::args_opt;
undef %Teng::Plugin::ArgsTest::;

my %args = (opt1 => 'a', opt2 => 'b');
(ref $db)->load_plugin('ArgsTest',
                         {
                          alias => {args_class => 'alias_args_class', args_opt => 'alias_args_opt'},
                          %args,
                         });

ok not defined &Mock::Basic::args_class;
ok not defined &Mock::Basic::args_opt;
ok defined &Mock::Basic::alias_args_class;
ok defined &Mock::Basic::alias_args_opt;

is $db->alias_args_class, ref $db;
is_deeply $db->alias_args_opt, \%args;

done_testing;
