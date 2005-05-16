# $Id: Depend.pm,v 1.8 2005/04/23 12:26:53 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Depend;
use Locale::TextDomain qw (video.dvdrip);

@ISA = qw ( Video::DVDRip::Base );

my $DEBUG = 0;

use Carp;
use strict;

my $ORDER = 0;
my %TOOLS = (
    transcode => {
    	order		=> ++$ORDER,
    	comment 	=> __"dvd::rip is nothing without transcode",
	optional	=> 0,
	get_version 	=> sub {
		qx[transcode -v 2>&1] =~ /v(\d+\.\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "0.6.2",
	suggested 	=> "0.6.14",
	installed	=> undef,	# set by ->new
	installed_num	=> undef,	# set by ->new
	min_num		=> undef,	# set by ->new
	suggested_num	=> undef,	# set by ->new
	installed_ok	=> undef,	# set by ->new
    },
    ImageMagick => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for preview image processing",
	optional	=> 0,
	get_version 	=> sub {
		qx[convert -version 2>&1] =~ /ImageMagick\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "4.0.0",
	suggested 	=> "5.5.3",
    },
    xvid4conf => {
    	order		=> ++$ORDER,
    	comment		=> __"xvid4 configuration tool",
	optional	=> 1,
	get_version 	=> sub {
		qx[xvid4conf -v 2>&1] =~ /(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "1.6",
	suggested 	=> "1.6",
    },
    subtitle2pgm => {
     	order		=> ++$ORDER,
   	comment		=> __"Needed for subtitles",
	optional	=> 1,
	get_version 	=> sub {
		qx[subtitle2pgm -h  2>&1] =~ /version\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "0.3",
	suggested 	=> "0.3",
    },
    rar => {
     	order		=> ++$ORDER,
   	comment		=> __"Needed for compressed subtitles",
	optional	=> 1,
	get_version 	=> sub {
		my $self = shift;
		my $rar = $self->config('rar_command');
		qx[$rar '-?' 2>&1] =~ /rar\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "2.71",
	max		=> "2.99",
	suggested 	=> "2.71",
    },
    mplayer => {
     	order		=> ++$ORDER,
   	comment		=> __"Needed for subtitle vobsub viewing",
	optional	=> 1,
	get_version 	=> sub {
		my $out = qx[mplayer --help 2>&1];
		wait;	# saw zombies on a Slackware system without it.
		if ( $out =~ /CVS/i ) {
		  return "cvs";
		} else {
		  $out =~ /MPlayer\s+(\d+\.\d+(\.\d+)?)/i;
		  return $1;
		}
	},
	convert 	=> 'default',
	min 		=> "0.90",
	suggested 	=> "0.90",
    },
    ogmtools => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for OGG/Vorbis",
	optional	=> 1,
	get_version 	=> sub {
		qx[ogmmerge -V 2>&1] =~ /v(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "1.0.0",
	suggested 	=> "1.0.0",
    },
    dvdxchap => {
    	order		=> ++$ORDER,
    	comment		=> __"For chapter progress bar (ogmtools)",
	optional	=> 1,
	get_version 	=> sub {
		qx[dvdxchap -V 2>&1] =~ /v(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "1.0.0",
	suggested 	=> "1.0.0",
    },
    mjpegtools => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for (S)VCD encoding",
	optional	=> 1,
	get_version 	=> sub {
		qx[mplex --help 2>&1] =~ /version\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "1.6.0",
	suggested 	=> "1.6.0",
    },
    cdrdao => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for (S)VCD burning",
	optional	=> 1,
	get_version 	=> sub {
		qx[cdrdao show-toc -h 2>&1] =~ /version\s+(\d+\.\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "1.1.7",
	suggested 	=> "1.1.7",
    },
    vcdimager => { 
    	order		=> ++$ORDER,
    	comment		=> __"Needed for (S)VCD burning",
	optional	=> 1,
	get_version 	=> sub {
		qx[vcdimager -V 2>&1] =~ /vcdimager.*?\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "0.7.12",
	suggested 	=> "0.7.12",
    },
    mkisofs => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for AVI/OGG burning",
	optional	=> 1,
	get_version 	=> sub {
		qx[mkisofs -version 2>&1] =~ /mkisofs\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "1.15",
	suggested 	=> "2.0",
    },
    cdrecord => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for AVI/OGG burning on CD",
	optional	=> 1,
	get_version 	=> sub {
		qx[cdrecord -version 2>&1] =~ /(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "0.7.12",
	suggested 	=> "2.0",
    },
    dvdrecord => {
    	order		=> ++$ORDER,
    	comment		=> __"Needed for AVI/OGG burning on DVD",
	optional	=> 1,
	get_version 	=> sub {
		qx[dvdrecord -version 2>&1] =~ /(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "0.2.0",
	suggested 	=> "0.2.1",
    },
    xine => {
    	order		=> ++$ORDER,
    	comment		=> __"Can be used to view DVD's/files",
	optional	=> 1,
	get_version 	=> sub {
		qx[xine -version 2>&1] =~ /v(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "0.9.13",
	suggested 	=> "0.9.15",
    },
    fping => {
    	order		=> ++$ORDER,
    	comment		=> __"Only for cluster mode master",
	optional	=> 1,
	get_version 	=> sub {
		qx[/usr/sbin/fping -v 2>&1] =~ /Version\s+(\d+\.\d+(\.\d+)?)/i;
		wait;	# saw zombies on a Slackware system without it.
		return $1;
	},
	convert 	=> 'default',
	min 		=> "2.2",
	suggested 	=> "2.4",
    },
);

my $OBJECT;

sub convert_default {
	my ($ver) = @_;
	return 990000 if $ver eq 'cvs';
	$ver =~ m/(\d+)(\.(\d+))?(\.(\d+))?(\.\d+)?/;
	$ver = $1*10000+$3*100+$5;
	$ver = $ver - 1 + $6 if $6;
	return $ver;
}

sub convert_none {
	return $_[0];
}

sub new {
	my $class = shift;
	
	return $OBJECT if $OBJECT;
	
	my $OBJECT = bless {}, $class;
	
	my $dependencies_ok = 1;
	
	my ($tool, $def);
	while ( ($tool, $def) = each %TOOLS ) {
		my $get_version = $def->{get_version};
		my $convert 	= $def->{convert};
		if ( $convert eq 'default' ) {
			$convert = \&convert_default;
		} elsif ( $convert eq 'none' ) {
			$convert = \&convert_none;
		}
		
		$DEBUG && print "[depend] $tool => ";

		my $version = &$get_version($OBJECT);

		if ( $version ne '' ) {
			$DEBUG && print "$version ";
			$def->{installed} = $version;
			$def->{installed_num} = &$convert($version);
			$DEBUG && print "=> $def->{installed_num}\n";
		} else {
			$DEBUG && print "NOT INSTALLED\n";
			$def->{installed} = "missing";
		}

		$def->{max_num}       = &$convert($def->{max}) if defined $def->{max};
		$def->{min_num}       = &$convert($def->{min});
		$def->{suggested_num} = &$convert($def->{suggested});
		$def->{installed_ok}  = $def->{installed_num} >= $def->{min_num};
		$def->{installed_ok}  = 0 if defined $def->{max} and
					     $def->{installed_num} > $def->{max_num};
		$dependencies_ok = 0
			if not $def->{optional} and not $def->{installed_ok};
	}
	
	$OBJECT->{ok} = $dependencies_ok;
	
	return $OBJECT;
}

sub ok				{ shift->{ok}				}
sub tools			{ \%TOOLS				}

sub has {
	my $self = shift;
	my ($command) = @_;

	return 0 if not exists $TOOLS{$command};
	return $TOOLS{$command}->{installed_ok};
}

sub version {
	my $self = shift;
	my ($command) = @_;

	return if not exists $TOOLS{$command};
	return $TOOLS{$command}->{installed_num};
}

sub gen_depend_table {
	my $tools = \%TOOLS;

	print <<__EOF;
<table border="1" cellpadding="4" cellspacing="1">
<tr class="tablehead">
  <td><b>Tool</b></td>
  <td><b>Comment</b></td>
  <td><b>Mandatory</b></td>
  <td><b>Suggested</b></td>
  <td><b>Minimum</b></td>
  <td><b>Maximum</b></td>
</tr>
__EOF

	foreach my $tool ( sort { $tools->{$a}->{order} <=> $tools->{$b}->{order} }
			   keys %{$tools} ) {
		my $def = $tools->{$tool};
		$def->{max} ||= "-";
		$def->{mandatory} = !$def->{optional} ? "Yes" : "No";
		print <<__EOF;
<tr>
  <td valign="top">$tool</td>
  <td valign="top">$def->{comment}</td>
  <td valign="top">$def->{mandatory}</td>
  <td valign="top">$def->{suggested}</td>
  <td valign="top">$def->{min}</td>
  <td valign="top">$def->{max}</td>
</tr>
__EOF
	}
	
	print "</table>\n";
}

1;
