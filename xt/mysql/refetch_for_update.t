use strict;
use warnings;
use utf8;

use t::Utils;
use xt::Utils::mysql;
use Test::More;

use lib './t';
use Mock::Basic;

use Teng;
use DBIx::Tracer;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

subtest 'refetch for update' => sub {
    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'Teng::Row';
    is $row->name, 'perl';

    my $tracer = DBIx::Tracer->new(sub {
        my %args = @_;
        like $args{sql}, qr/FOR UPDATE/ms;
    });

    my $refetch_row = $row->refetch({for_update => 1});
    undef $tracer;

    isa_ok $refetch_row, 'Teng::Row';
    is $refetch_row->name, 'perl';
};

done_testing;
