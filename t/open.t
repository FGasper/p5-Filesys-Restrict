#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use File::Temp ();

use Filesys::Restrict;

my $tempdir = File::Temp::tempdir();

my $good_dir = "$tempdir/good";

mkdir $good_dir;

{
    my $check = Filesys::Restrict::create( sub {
        my $path = $_[1];

        return $path =~ m<\A\Q$good_dir\E/>;
    } );

    my $fh;

    lives_ok(
        sub { open $fh, '<', "$good_dir/whatwhat" },
        '3-arg, approve',
    );

    throws_ok(
        sub { open $fh, '<', "$tempdir/whatwhat" },
        'Filesys::Restrict::X::Forbidden',
        '3-arg, fail',
    );

    throws_ok(
        sub { open $fh, '<', *STDIN },
        'Filesys::Restrict::X::Forbidden',
        '3-arg, pass STDOUT glob as normal file load',
    );

    throws_ok(
        sub { open $fh, '<', \*STDIN },
        'Filesys::Restrict::X::Forbidden',
        '3-arg, pass STDOUT globref as normal file load',
    );

    lives_ok(
        sub { open $fh, '<&', *STDIN },
        '3-arg, dupe STDOUT glob',
    );

    lives_ok(
        sub { open $fh, '<&', \*STDIN },
        '3-arg, dupe STDOUT globref',
    );

    lives_ok(
        sub { open $fh, '<&=', *STDIN },
        '3-arg, new FH STDOUT glob',
    );

    lives_ok(
        sub { open $fh, '<&=', \*STDIN },
        '3-arg, new FH STDOUT globref',
    );
}

done_testing;
