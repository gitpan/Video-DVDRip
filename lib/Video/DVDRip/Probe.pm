# $Id: Probe.pm,v 1.10 2002/01/03 17:40:00 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Probe;

use base Video::DVDRip::Base;

use Carp;
use strict;

sub width		{ shift->{width}	    	}
sub height		{ shift->{height}	    	}
sub aspect_ratio	{ shift->{aspect_ratio}	    	}
sub video_mode		{ shift->{video_mode}	    	}
sub letterboxed		{ shift->{letterboxed}	    	}
sub frames		{ shift->{frames}		}
sub runtime		{ shift->{runtime}		}
sub frame_rate		{ shift->{frame_rate}		}
sub audio_size		{ shift->{audio_size}		}
sub bitrates		{ shift->{bitrates}		}	# href
sub audio_tracks	{ shift->{audio_tracks}		}	# lref
sub probe_output	{ shift->{probe_output}	    	}
sub chapters		{ shift->{chapters}	    	}
sub viewing_angles	{ shift->{viewing_angles}	}

sub set_width		{ shift->{width}	= $_[1]	}
sub set_height		{ shift->{height}	= $_[1]	}
sub set_aspect_ratio	{ shift->{aspect_ratio}	= $_[1]	}
sub set_video_mode	{ shift->{video_mode}	= $_[1]	}
sub set_letterboxed	{ shift->{letterboxed}	= $_[1]	}
sub set_frames		{ shift->{frames}	= $_[1] }
sub set_runtime		{ shift->{runtime}	= $_[1] }
sub set_frame_rate	{ shift->{frame_rate}	= $_[1] }
sub set_audio_size	{ shift->{audio_size}	= $_[1] }
sub set_bitrates	{ shift->{bitrates}	= $_[1] }
sub set_audio_tracks	{ shift->{audio_tracks}	= $_[1] }
sub set_probe_output	{ shift->{probe_output}	= $_[1]	}
sub set_chapters	{ shift->{chapters}	= $_[1]	}
sub set_viewing_angles	{ shift->{viewing_angles}=$_[1]	}

sub analyze {
	my $class = shift;
	my %par = @_;
	my  ($probe_output) = @par{'probe_output'};

	my ($width, $height, $aspect_ratio, $video_mode, $letterboxed);
	my ($frames, $runtime, $frame_rate, $audio_size, $chapters, $angles);

	($width)	= $probe_output =~ /frame\s+size:\s*-g\s+(\d+)/;
	($height)	= $probe_output =~ /frame\s+size:\s*-g\s+\d+x(\d+)/;
	($aspect_ratio)	= $probe_output =~ /aspect\s*ratio:\s*(\d+:\d+)/;
	($video_mode)	= $probe_output =~ /dvd_reader.*?(pal|ntsc)/i;
	($letterboxed)	= $probe_output =~ /dvd_reader.*?(letterboxed)/;
	($frames)       = $probe_output =~ /V:\s*(\d+)\s*frames/;
	($runtime)      = $probe_output =~ /playback time:.*?(\d+)\s*sec/;
	($frame_rate)   = $probe_output =~ /frame\s+rate:\s+-f\s+([\d.]+)/;
	($audio_size)   = $probe_output =~ /A:\s*([\d.]+)/;
	($chapters)     = $probe_output =~ /(\d+)\s+chapter/;
	($angles)       = $probe_output =~ /(\d+)\s+angle/;

	$letterboxed = $letterboxed ? 1 : 0;
	$video_mode  = lc ($video_mode);

	# transcode 0.5.3 workaround
	$frames ||= $runtime * $frame_rate;

	my ($size, %bitrates, $bitrate);
	while ( $probe_output =~ /CD:\s*(\d+)/g ) {
		$size = $1;
		($bitrate) = $probe_output =~ /CD:\s*$size.*?\@\s*([\d.]+)\s*kbps/;
		($bitrates{$size}) = int($bitrate);
	}

	my (@audio_tracks);
	while ( $probe_output =~
		/audio\s+track:\s*-a\s*(\d+).*?-e\s+(\d+),(\d+),(\d+)/g ) {
		$audio_tracks[$1] = {
			sample_rate  => $2,
			sample_width => $3,
		};
	}

	my $i = 0;
	while ( $probe_output =~ /dvd_reader.c.*?ac3\s+(\w+).*?(\d+)Ch/g ) {
		$audio_tracks[$i]->{type}     = "AC3";
		$audio_tracks[$i]->{lang}     = $1;
		$audio_tracks[$i]->{channels} = $2;
		++$i;
	}

	my $self = {
		probe_output 	=> $probe_output,
		width	   	=> $width,
		height     	=> $height,
		aspect_ratio 	=> $aspect_ratio,
		video_mode  	=> $video_mode,
		letterboxed  	=> $letterboxed,
		frames		=> $frames,
		runtime		=> $runtime,
		frame_rate	=> $frame_rate,
		chapters	=> $chapters,
		audio_size      => $audio_size,
		bitrates	=> \%bitrates,
		audio_tracks    => \@audio_tracks,
		viewing_angles  => $angles,
	};
	
	return bless $self, $class;
}

1;
