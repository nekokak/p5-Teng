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

subtest 'bulk_insert with opt' => sub {
    my $tracer = DBIx::Tracer->new(sub {
        my %args = @_;
        like $args{sql}, qr/^INSERT IGNORE INTO/ms;
        like $args{sql}, qr/ON DUPLICATE KEY UPDATE/ms;
    });

    $db->bulk_insert('mock_basic',
        [
            { id   => 1, name => 'perl' },
            { id   => 2, name => 'ruby' },
        ],
        +{
            prefix => 'INSERT IGNORE INTO',
            update => { name => 'updated' },
        }
    );
    ok not $@;
};

done_testing;
