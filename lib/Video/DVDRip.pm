# $Id: DVDRip.pm,v 1.82 2002/09/22 18:23:17 joern Exp $

package Video::DVDRip;

$VERSION = "0.46";

use Carp;
use FileHandle;

init: {
	# skip transcode check during "make test". This makes
	# automatic CPAN testing fail erroneously and makes
	# problems during first dvd::rip install, when the
	# use has no "." in PATH, because then dr_splitpipe isn't
	# found.
	last if $ENV{PERL_DL_NONLAZY} == 1;

	my @path = split(":", $ENV{PATH});

	my @programs = qw (
		rm convert identify
		transcode tcscan tccat
		tcextract tcdecode
		dr_splitpipe dr_progress
	);
	
	my $missing = "";
	PROGRAM: foreach my $program ( @programs ) {
		PATH: foreach my $path ( @path ) {
			next PROGRAM if -x "$path/$program";
		}
		$missing .= "$program, ";
	}
	
	$missing =~ s/, $//;
	
	if ( $missing ) {
		croak 	"Missing the following programs.\n".
			"Please install them and configure your PATH:\n\n".
			"$missing\n";
	}

	my $fh = FileHandle->new;
	open ($fh, "transcode -h 2>&1 |") or croak "can't fork transcode -h";
	my $ver = <$fh>;
	close $fh;

	$ver =~ m/v(\d+)\.(\d+)\.(\d+)/;
	
	# -------------------------
	# transcode version numbers:
	# -------------------------
	# 0.5.3    => 503
	# 0.6.0    => 600
	# 1.2.7    => 100207
	# 99.99.99 => 999999
	# -------------------------

	$TC::VERSION = $1*10000+$2*100+$3;
	$TC::VERSION ||= 0;

	if ( $TC::VERSION < 600 ) {
		print "Sorry, transcode versions prior 0.6.0pre4 are no longer supported.\n".
		      "Please upgrade transcode.\n";
		exit 1;
	}
}

1;

__END__

=head1 NAME

Video::DVDRip - GUI for copying DVDs, based on an open Low Level API

=head1 DESCRIPTION

This Perl module consists currently of two major components:

  1. A low level OO style API for ripping and transcoding
     DVD video, which is based on Thomas Oestreichs program
     transcode, a Linux Video Stream Processing Tool.
     This API is currently well undocumented.

  2. A Gtk+ based Perl program called 'dvd::rip' which provides
     a nice GUI to control all necessary steps from ripping,
     adjusting all parameters and transcoding the video to
     the format you desire.

The distribution name is derived from the Perl namespace it occupies:
Video::DVDRip. Although the DVD Ripper GUI is called dvd::rip, because
it's shorter and easier to pronounce (if you omit the colons... ;)

You'll find all information regarding installation and usage of
dvd::rip in the README file shipped with the distribution or
on the dvd::rip homepage:

  http://www.exit1.org/dvdrip/

=head1 COPYRIGHT

Copyright (C) 2001-2002 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
