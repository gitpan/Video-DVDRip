# $Id: DVDRip.pm,v 1.6 2001/11/29 20:51:15 joern Exp $

package Video::DVDRip;

$VERSION = "0.20";

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

As of this writing, transcode 0.5.0 is the stable release
dvd::rip is tested with. dvd::rip expects all transcode binaries
to be found in the standard search PATH.

B<Image Magick>

For image processing dvd::rip uses the widely distributed software package
Image Magick, at least the programs identify and convert should be
installed on your system. All versions above version 4 should work
(actually tested with 5.3.1). dvd::rip does not use Perl Magick.

B<Perl Modules>

For its GUI component dvd::rip needs the Perl Gtk module, which presumes
Gtk+ version 1.2 or higher. I tested dvd::rip with Version Perl Gtk 0.7008.

You can find the Gtk module on CPAN, e.g.:

  http://www.perl.com/CPAN/modules/by-module/Gtk/

B<xine>

If you have the movie player xine installed, you can preview selected
DVD titles with the appropriate audio channels. Maybe I'll support
mplayer, too, in upcoming versions.

=head1 DOWNLOADING

You can download dvd::rip from any CPAN mirror. You will
find it in the following directory:

  http://www.perl.com/CPAN/modules/by-authors/id/J/JR/JRED/

I recommend downloading from a mirror, which are listed here

  http://www.perl.com/CPAN/SITES.html

You'll also find recent information, some screenshots and documentation
on my homepage:

  http://www.netcologne.de/~nc-joernre/

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

=head1 AUTHOR

Joern Reder <joern@zyn.de>

You can contact me by email. Please place the word "dvd::rip"
in the subject, because this helps me classifying your email
correctly. Thanks.

=head1 COPYRIGHT

Copyright (C) 2001 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
