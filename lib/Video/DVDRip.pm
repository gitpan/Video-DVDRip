# $Id: DVDRip.pm,v 1.45 2002/03/13 18:16:10 joern Exp $

package Video::DVDRip;

$VERSION = "0.35";

use Carp;
use FileHandle;

sub init {
	my $thing = shift;
	
	my @path = split(":", $ENV{PATH});
	my @programs = qw (
		rm convert identify
		transcode tcscan tccat
		tcextract tcdecode splitpipe
		
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

	1;
}

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

=head1 PREREQUISITES

B<transcode>

dvd::rip delegates all the low level DVD handling to transcode,
which can be obtained here:

  http://www.theorie.physik.uni-goettingen.de/~ostreich/transcode/

dvd::rip expects all transcode binaries to be found in the
standard search PATH.

B<Image Magick>

For image processing dvd::rip uses the widely distributed software package
Image Magick, at least the programs identify and convert should be
installed on your system. All versions above version 4 should work
(actually tested with 5.3.1). dvd::rip does not use Perl Magick.

B<Perl Modules>

For its GUI component dvd::rip needs the Perl Gtk module, which presumes
Gtk+ version 1.2 or higher. I tested dvd::rip with Version Perl Gtk 0.7008.

You can find the Gtk module on CPAN, e.g.:

  http://www.perl.org/CPAN/modules/by-module/Gtk/

For cluster mode you need the Event and the Storable module:

  http://www.perl.org/CPAN/modules/by-module/Event/
  http://www.perl.org/CPAN/modules/by-module/Storable/

B<xine>

If you have the movie player xine installed, you can preview selected
DVD titles with the appropriate audio channels. Maybe I'll support
mplayer, too, in upcoming versions.

=head1 DOWNLOADING

You can download dvd::rip from any CPAN mirror. You will
find it in the following directory:

  http://www.perl.org/CPAN/modules/by-authors/id/J/JR/JRED/

I recommend downloading from a mirror, which are listed here

  http://www.perl.org/CPAN/SITES.html

You'll also find recent information, some screenshots and documentation
on the dvd::rip homepage:

  http://www.exit1.org/dvdrip/

=head1 INSTALLATION

First install all packages listed in the PREREQUISITES section.

Then extract the .tar.gz file, change into the created directory
and generate the Makefile and execute make:

  perl Makefile.PL
  make

Among other things this builds the binary program 'splitpipe',
which uses dvd::rip for ripping and scanning the DVD in the
same run.

Now it's up to you to type

  make install
  
which installs all the Perl modules in your Perl library path,
and the two executables

  dvdrip
  splitpipe

in your Perl bin directory. Otherwise you can use dvd::rip right
here and now by executing the 'dvdrip' program from the build
directory.

=head1 BASE CONFIGURATION / PREFERENCES

On first startup of dvd::rip you should check the global preferences
in the Edit menu. Enter your DVD configuration and data
directory here. The defaults will most likely not work on your system.

These settings are stored in your home directory:

  ~/.dvdriprc

Remove this file for falling back to the defaults.

=head1 NOW HAVE FUN

Create a new project by choosing the appropriate entry of the main
menu. The GUI should be more or less self-explanatory. Please check
my homepage for more details on using dvd::rip.

=head1 BUG REPORTS / CONTRIBUTING

If you find bugs or have suggestions which make dvd::rip a better tool:
don't hesitate to send me emails (see AUTHOR section below).
	
If you find a bug which crashes dvd::rip, please add the following
information to your report:
	
  1. information about your Linux installation, which may be interesting
     (Kernel version, Distro version, X11 Version)

  2. information about your Perl installation. Simply send me
     the output of the "perl -V" command.

  3. if possible a description how the bug can be reproduced.

Patches are welcome. I prefer unified context diffs created this way:

  diff -urN Video-DVDRip-0.21 Video-DVDRip-0.21.patched

where Video-DVDRip-0.21 is the root directory of the original
distribution and Video-DVDRip-0.21.patched your modified version.

If you encounter problems ripping specific DVDs, this is probably
a transcode problem. Maybe you want to report this directly to Thomas
Östreich. If you're not sure about this, report the problem to me
and I'll see what I can do for you.

=head1 AUTHOR

Joern Reder <joern@zyn.de>

You can contact me by email. Please place the word "dvd::rip"
everywhere in the subject, in addition to your real topic, because
this helps me classifying your email correctly. Thanks.

I'm native german speaker, so you can send your mails in german,
if you want. The others have to accept my rough english ;)

=head1 COPYRIGHT

Copyright (C) 2001-2002 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
