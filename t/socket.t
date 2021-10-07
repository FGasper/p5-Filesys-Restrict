#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use File::Temp ();
use Socket ();

use Filesys::Restrict;

my $tempdir = File::Temp::tempdir();

my $good_dir = "$tempdir/good";

mkdir $good_dir;

{
    my $check = Filesys::Restrict::create( sub {
        my $path = $_[1];

        return $path =~ m<\A\Q$good_dir\E/>;
    } );

    my $good_path = "$good_dir/s";

    my $good_sockname = Socket::pack_sockaddr_un($good_path);
    my $bad_sockname = Socket::pack_sockaddr_un("$tempdir/bad");

    socket my $s, Socket::AF_UNIX, Socket::SOCK_STREAM, 0;

    lives_ok(
        sub { connect $s, $good_sockname },
        'connect() to UNIX socket in authorized path',
    );

    throws_ok(
        sub { connect $s, $bad_sockname },
        'Filesys::Restrict::X::Forbidden',
        'connect() to UNIX socket in forbidden path',
    );

    lives_ok(
        sub { bind $s, $good_sockname },
        'bind() to UNIX socket in authorized path',
    );

    throws_ok(
        sub { bind $s, $bad_sockname },
        'Filesys::Restrict::X::Forbidden',
        'bind() to UNIX socket in forbidden path',
    );
}

done_testing();
