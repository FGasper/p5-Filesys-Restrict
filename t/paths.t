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

    _test_sysopen();
    _test_truncate();
    _test_2paths();
    _test_last_arg_nofh();
    _test_mkdir();
    _test_system();
}

sub _test_system {
    my $script_path = "$good_dir/script.pl";

    {
        open my $fh, '>', $script_path or die "open($script_path): $!";
        chmod 0755, $fh;
        syswrite $fh, join(
            $/,
            "#!$^X",
            "exit 0;",
        );
    }

    lives_ok(
        sub { system $script_path },
        "simple system on approved path",
    );

    lives_ok(
        sub { system { $script_path } $script_path },
        "system { .. } on approved path",
    );

    throws_ok(
        sub { system "$tempdir/bad" },
        'Filesys::Restrict::X::Forbidden',
        "simple system on forbidden path",
    );

    throws_ok(
        sub { system { "$tempdir/bad" } "$tempdir/bad" },
        'Filesys::Restrict::X::Forbidden',
        "system { .. } on forbidden path",
    );
}

sub _test_mkdir {
    my $good_path = "$good_dir/gooddir";
    my $bad_path = "$tempdir/one";

    lives_ok(
        sub { mkdir $good_path },
        "mkdir (1-arg) on approved path",
    );

    throws_ok(
        sub { mkdir $bad_path },
        'Filesys::Restrict::X::Forbidden',
        "mkdir (1-arg) on forbidden path",
    );

    lives_ok(
        sub { mkdir $good_path, 0755 },
        "mkdir (2-arg) on approved path",
    );

    throws_ok(
        sub { mkdir $bad_path, 0755 },
        'Filesys::Restrict::X::Forbidden',
        "mkdir (2-arg) on forbidden path",
    );
}

sub _test_last_arg_nofh {
    my $good_path = "$good_dir/one";
    my $bad_path = "$tempdir/one";

    lives_ok(
        sub { readlink $good_path },
        "readlink on approved path",
    );

    throws_ok(
        sub { readlink $bad_path },
        'Filesys::Restrict::X::Forbidden',
        "readlink on forbidden path",
    );

    lives_ok(
        sub { rmdir $good_path },
        "rmdir on approved path",
    );

    throws_ok(
        sub { rmdir $bad_path },
        'Filesys::Restrict::X::Forbidden',
        "rmdir on forbidden path",
    );

    lives_ok(
        sub { opendir my $fh, $good_path },
        "opendir on approved path",
    );

    throws_ok(
        sub { opendir my $fh, $bad_path },
        'Filesys::Restrict::X::Forbidden',
        "opendir on forbidden path",
    );
}

sub _test_2paths {
    my $good_path = "$good_dir/one";
    my $bad_path = "$tempdir/one";

    for my $fn ( qw( rename symlink link ) ) {
        lives_ok(
            sub { die if !eval "$fn '$good_path', '$good_path'; 1" },
            "$fn on approved paths",
        );

        throws_ok(
            sub { die if !eval "$fn '$bad_path', '$good_path'; 1" },
            'Filesys::Restrict::X::Forbidden',
            "$fn( forbidden => approved )",
        );

        throws_ok(
            sub { die if !eval "$fn '$good_path', '$bad_path'; 1" },
            'Filesys::Restrict::X::Forbidden',
            "$fn( approved => forbidden )",
        );

        throws_ok(
            sub { die if !eval "$fn '$bad_path', '$bad_path'; 1" },
            'Filesys::Restrict::X::Forbidden',
            "$fn( forbidden => forbidden )",
        );
    }
}

sub _test_truncate {
    lives_ok(
        sub { truncate "$good_dir/haha", 0 },
        "truncate on approved path",
    );

    throws_ok(
        sub { truncate "$tempdir/haha", 0 },
        'Filesys::Restrict::X::Forbidden',
        "truncate on forbidden path",
    );
}

sub _test_sysopen {
    lives_ok(
        sub { sysopen my $fh, "$good_dir/haha", 0 },
        "sysopen (3-arg) on approved path",
    );

    lives_ok(
        sub { sysopen my $fh, "$good_dir/haha", 0, 0 },
        "sysopen (4-arg) on approved path",
    );

    throws_ok(
        sub { sysopen my $fh, "$tempdir/haha", 0 },
        'Filesys::Restrict::X::Forbidden',
        "sysopen (3-arg) on forbidden path",
    );

    throws_ok(
        sub { sysopen my $fh, "$tempdir/haha", 0, 0 },
        'Filesys::Restrict::X::Forbidden',
        "sysopen (4-arg) on forbidden path",
    );
}

done_testing;
