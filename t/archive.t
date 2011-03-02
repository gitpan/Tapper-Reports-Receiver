#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Tapper::Reports::Receiver;

my $tap_archive = 't/tap-archive-1.tgz';

my $filecontent;
my $FH;
open $FH, "<", $tap_archive and do
{
        local $/;
        $filecontent = <$FH>;
        close $FH;
};

# ------------------------------------------------------------

my $util = Tapper::Reports::Receiver::Util->new;
$util->{tap} = $filecontent;
is ($util->tap_mimetype, 'application/x-gzip', "TAP mimetype - compressed");
is($util->tap_is_archive, 1, "TAP archive recognized");

# ------------------------------------------------------------

$util->{tap} = "1..2
ok
ok
";
is ($util->tap_mimetype, 'text/plain', "TAP mimetype - text");
is($util->tap_is_archive, 0, "TAP text recognized");

# ------------------------------------------------------------

done_testing();
