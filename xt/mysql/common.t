use strict;
use warnings;
use xt::Utils::mysql;
use Test::More;
use File::Find;

my @files;

find({
    wanted => sub {
        push @files, $_ if -f $_ &&  /\.t$/
    },
    no_chdir => 1,
}, './t/002_common');

for my $file (@files) {
    subtest "$file" => sub { do "$file" };
}

done_testing;
