# perl -w

use strict;
use warnings;
use FindBin qw($Bin);
use autodie;
$ENV{PERL5LIB} .= ':../../../lib';

my %dist = (
    'p5-dbix-skinny-schema-loader' => q{git://github.com/nekoya/p5-dbix-skinny-schema-loader.git},
    'p5-dbix-skinny-proxy_table'   => q{git://github.com/walf443/p5-dbix-skinny-proxy_table.git},
    'p5-dbix-skinny-pager'         => q{git://github.com/walf443/p5-dbix-skinny-pager.git},
);

my $distdir = 'externals';

chdir $Bin;
mkdir $distdir if not -e $distdir;

while(my($name, $repo) = each %dist){
    chdir "$Bin/$distdir";

    print "Go $name ($repo)\n";

    if(!(-e "$name")){
        system "git clone $repo $name";
        chdir $name;
    }
    else{
        chdir $name;
        system "git pull";
    }

    print "$^X Makefile.PL\n";
    system("$^X Makefile.PL 2>&1 |tee ../$name.log");

    print "make\n";
    system("make 2>&1 >>../$name.log");

    print "make test\n";
    system("make test 2>&1 |tee -a ../$name.log")
}
