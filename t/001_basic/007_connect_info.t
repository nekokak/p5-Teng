use t::Utils;
use Mock::Basic;
use Test::More;

my $db = Mock::Basic->new(
    {
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    }
);

my $connect_info = $db->connect_info();

is $connect_info->{dsn}, 'dbi:SQLite:';
is $connect_info->{username}, '';
is $connect_info->{password}, '';

done_testing;
