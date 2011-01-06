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

    use_ok "Mock::DeprecatedSetup";
    close $fh;

    like $buffer, qr/use DBIx::Skinny setup => { \.\.\. } has been deprecated\. Please use connect_info instead/;
}
done_testing;
