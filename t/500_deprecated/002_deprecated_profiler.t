use strict;
use Test::More;
use t::Utils;

BEGIN {
    if ($] < 5.008) { # just in case..
        plan(skip_all => "requires perl 5.8 or greater");
    }
}

{
    my $buffer = '';
    open my $fh, '>', \$buffer or die "Could not open in-memory buffer";
    *STDERR = $fh;

    use_ok "Mock::DeprecatedProfiler";
    close $fh;

    like $buffer, qr/use DBIx::Skinny connect_info => { profiler => \.\.\. } has been deprecated\. Please use use DBIx::Skinny profiler => \.\.\. instead/;
}
done_testing;
