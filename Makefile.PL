use ExtUtils::MakeMaker;

use Socket;

my $has_unix_sockets = eval { socket(my $sock, Socket::PF_UNIX(), Socket::SOCK_STREAM(), 0); 1 };

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Filesys::Restrict',
    VERSION_FROM      => 'lib/Filesys/Restrict.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Filesys/Restrict.pm', # retrieve abstract from module
       AUTHOR         => [
            'cPanel, L. L. C. (CPANEL)',
        ],
      ) : ()
    ),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-Wall -I.', # e.g., '-I. -I/usr/include/other'
    LICENSE           => "perl_5",

    CCFLAGS        => join(
        q< >,
        $Config{'ccflags'},
        ( $has_unix_sockets ? '-DFR_HAS_UNIX_SOCKETS' : () ),
    ),

    # Needs X::Tiny
    MIN_PERL_VERSION => '5.10.0',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/cpanel/p5-Filesys-Restrict.git',
                web => 'https://github.com/cpanel/p5-Filesys-Restrict',
            },
            bugtracker => {
                web => 'https://github.com/cpanel/p5-Filesys-Restrict/issues',
            },
        },
    },

    PREREQ_PM => {
        'parent' => 0,
        'X::Tiny' => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::FailWarnings' => 0,
        'File::Temp' => 0,
        'Test::Exception' => 0,
    },
);
