package Filesys::Restrict;

use strict;
use warnings;

our $VERSION = '0.01_01';

=encoding utf-8

=head1 NAME

Filesys::Restrict - Restrict filesystem access

=head1 SYNOPSIS

    {
        my $check = Filesys::Restrict::create(
            sub {
                my ($op, $path) = @_;

                return 1 if $path =~ m<^/safe/place/>;

                # Deny access to anything else:
                return 0;
            },
        );

        # In this block, most Perl code will throw if it tries
        # to access anything outside of /safe/place.
    }

    # No more filesystem checks here.

=head1 DESCRIPTION

This module is a reasonable-best-effort at preventing Perl code from
accessing files you don’t want to allow. One potential application of
this is to restrict filesystem access to F</tmp> in tests.

=head1 B<THIS> B<IS> B<NOT> B<A> B<SECURITY> B<TOOL!>

This module cannot prevent any and all unintended filesystem access.
The following are some known ways to circumvent it:

=over

=item * Use a module like L<POSIX>, or C<system()>.

=item * Use C code via XS.

=item * Use one of C<open()>’s more esoteric forms.
This module tries to parse typical C<open()> arguments but doesn’t
“bend over backward”. The 2- and 3-argument forms are assumed to be
valid if there’s an unrecognized format, and we ignore the 1-argument
form entirely.

=item * Call C<do()> or C<require()>. (See below.)

=back

Concerning this last note: we I<could> restrict C<do()> and C<require()>.
These, though, are a bit different from other built-ins because they
don’t facilitate reading arbitrary data off the filesystem; rather,
they’re narrowly-scoped to bringing in additional Perl code.

If you have a use case where it’s useful to restrict these,
file a feature request.

=head1 SEE ALSO

L<fanotify(7)> on Linux provides a method of real-time access control
via the kernel. See L<Linux::Fanotify> and L<Linux::Perl> for Perl
implementations.

=cut

#----------------------------------------------------------------------

use Filesys::Restrict::X ();

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our $_AUTHORIZE = undef;

#----------------------------------------------------------------------

=head1 FUNCTIONS

=head2 $obj = create( sub { .. } )

Creates an opaque object that installs an access-control callback.
Any existing access-control callback is saved and restored whenever
$obj is DESTROYed.

The access-control callback is called with two arguments:

=over

=item * The name of the Perl op that requests filesystem access.
The names come from C<PL_op_desc> in Perl’s L<opcode.h> header file;
they should correlate to the actual built-in called.

=item * The filesystem path in question.

=back

The callback can end in one of three ways:

=over

=item * Return truthy to confirm access to the path.

=item * Return falsy to cause a L<Filesys::Restrict::X::Forbidden>
instance to be thrown.

=item * Throw a custom exception.

=back

=cut

sub create {
    die 'Void context is meaningless!' if !defined wantarray;

    my $cb = $_[0];

    if (!$cb) {
        die( (caller 0)[3] . ' requires a callback!' );
    }

    if (!ref($cb) || !UNIVERSAL::isa($cb, 'CODE')) {
        die( (caller 0)[3] . " requires a callback, not “$cb”!" );
    }

    my $stored_cb = $_AUTHORIZE;

    $_AUTHORIZE = $cb;

    return bless \$stored_cb, 'Filesys::Restrict::Guard';
}

sub _CROAK {
    local $_AUTHORIZE;
    die Filesys::Restrict::X->create('Forbidden', @_);
}

#----------------------------------------------------------------------

package Filesys::Restrict::Guard;

sub DESTROY {
    $Filesys::Restrict::_AUTHORIZE = ${ $_[0] };
}

1;
