# $Id: Probe.pm,v 1.15.2.1 2002/12/03 20:19:02 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Probe;

use base Video::DVDRip::Base;

use Video::DVDRip::ProbeAudio;

use Carp;
use strict;

sub width			{ shift->{width}	    		}
sub height			{ shift->{height}	    		}
sub aspect_ratio		{ shift->{aspect_ratio}	    		}
sub video_mode			{ shift->{video_mode}	    		}
sub letterboxed			{ shift->{letterboxed}	    		}
sub frames			{ shift->{frames}			}
sub runtime			{ shift->{runtime}			}
sub frame_rate			{ shift->{frame_rate}			}
sub audio_size			{ shift->{audio_size}			}
sub bitrates			{ shift->{bitrates}			}	# href
sub audio_tracks		{ shift->{audio_tracks}			}	# lref
sub probe_output		{ shift->{probe_output}	    		}
sub audio_probe_output		{ shift->{audio_probe_output}  		}
sub chapters			{ shift->{chapters}	    		}
sub viewing_angles		{ shift->{viewing_angles}		}

sub set_width			{ shift->{width}		= $_[1]	}
sub set_height			{ shift->{height}		= $_[1]	}
sub set_aspect_ratio		{ shift->{aspect_ratio}		= $_[1]	}
sub set_video_mode		{ shift->{video_mode}		= $_[1]	}
sub set_letterboxed		{ shift->{letterboxed}		= $_[1]	}
sub set_frames			{ shift->{frames}		= $_[1] }
sub set_runtime			{ shift->{runtime}		= $_[1] }
sub set_frame_rate		{ shift->{frame_rate}		= $_[1] }
sub set_audio_size		{ shift->{audio_size}		= $_[1] }
sub set_bitrates		{ shift->{bitrates}		= $_[1] }
sub set_audio_tracks		{ shift->{audio_tracks}		= $_[1] }
sub set_probe_output		{ shift->{probe_output}		= $_[1]	}
sub set_audio_probe_output	{ shift->{audio_probe_output}	= $_[1]	}
sub set_chapters		{ shift->{chapters}		= $_[1]	}
sub set_viewing_angles		{ shift->{viewing_angles}	= $_[1]	}

sub analyze {
	my $class = shift;
	my %par = @_;
	my ($probe_output, $title) = @par{'probe_output','title'};

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
		if ( $2 and $3 ) {
			$audio_tracks[$1] = {
				sample_rate  => $2,
				sample_width => $3,
				bitrate      => undef,	# later set by analyze_audio
				tc_option_n  => undef,	# later set by analyze_audio
				scan_result  => undef,  # later set by Title->scan
			};
		}
	}

	my $i = 0;
	while ( $probe_output =~ /\(dvd_reader.c\)\s+([^\s]+)\s+(\w+).*?(\d+)Ch/g ) {
		$audio_tracks[$i]->{type}     = lc($1);
		$audio_tracks[$i]->{lang}     = lc($2);
		$audio_tracks[$i]->{channels} = $3;
		++$i;
	}

	my @audio_track_objects;
	my @tc_audio_track_objects;
	$i = 0;
	foreach my $audio ( @audio_tracks ) {
		push @audio_track_objects, Video::DVDRip::ProbeAudio->new (
			type		=> $audio->{type},
			lang		=> $audio->{lang},
			channels	=> $audio->{channels},
			sample_rate	=> $audio->{sample_rate},
		);
		push @tc_audio_track_objects, Video::DVDRip::Audio->new (
			tc_nr 		=> $i,
			tc_target_track	=> ($i==0 ? 0 : -1),
			tc_audio_codec	=> "mp3",
			tc_bitrate	=> 128,
			tc_mp3_quality	=> 0,
		);
		++$i;
	}

	$title->set_tc_audio_tracks ( \@tc_audio_track_objects );

	$title->set_audio_channel(@audio_tracks? 0 : -1);

	my %subtitles;
	my $sid;
	while ( $probe_output =~ /subtitle\s+(\d+)=<([^>]+)>/g ) {
		$sid = $1 + 0;
		$subtitles{$sid} = Video::DVDRip::Subtitle->new (
			id    => $sid,
			lang  => $2,
			title => $title,
		);
	}
	
	$title->set_subtitles (\%subtitles);

	if ( defined $sid ) {
		# we have subtitles
		$title->set_selected_subtitle_id (0);
	} else {
		$title->set_selected_subtitle_id (-1);
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
		audio_tracks    => \@audio_track_objects,
		viewing_angles  => $angles,
	};
	
	return bless $self, $class;
}

sub analyze_audio {
	my $self = shift;
	my %par = @_;
	my  ($probe_output, $title) =
	@par{'probe_output','title'};
	
	$self->set_audio_probe_output ( $probe_output );
	
	my @lines = split (/\n/, $probe_output);
	my $nr;
	for ( my $i=0; $i < @lines; ++$i ) {
		if ( $lines[$i] =~ /audio\s+track:\s+-a\s+(\d+).*?-n\s+([x0-9]+)/ ) {
			$nr = $1;
			next if not defined $self->audio_tracks->[$nr];
			$title->tc_audio_tracks->[$nr]->set_tc_option_n ($2);
			++$i;
			$lines[$i] =~ /bitrate\s*=(\d+)/;
			$self->audio_tracks->[$nr]->set_bitrate($1);
		}
	}
	
	1;
}


1;
