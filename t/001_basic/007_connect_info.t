use t::Utils;
use Mock::Basic;
use Test::More;

Mock::Basic->connect_info(
    {
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    }
);

my $connect_info = Mock::Basic->connect_info();

is $connect_info->{dsn}, 'dbi:SQLite:';
is $connect_info->{username}, '';
is $connect_info->{password}, '';

done_testing;
