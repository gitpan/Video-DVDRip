# $Id: BitrateCalc.pm,v 1.12 2004/04/11 23:36:19 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::BitrateCalc;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;
use strict;

my $VCD_ADDITION_FACTOR = 2324/2048;
my $VCD_DISC_OVERHEAD   = 600 * 2324;
my $AVI_VIDEO_OVERHEAD  = 45;
my $AVI_AUDIO_OVERHEAD  = 15;
my $OGG_SIZE_OVERHEAD   = 0.25 / 100;
my $VCD_VIDEO_RATE	= 1152;
my $MAX_SVCD_SUM_RATE	= 2748;
my $MAX_SVCD_VIDEO_RATE	= 2600;
my $MAX_VIDEO_RATE	= 6000;

my %VORBIS_NOMINAL_BITRATES = (
	0  =>  60,
	1  =>  80,
	2  =>  96,
	3  => 112,
	4  => 128,
	5  => 160,
	6  => 192,
	7  => 224,
	8  => 256,
	9  => 320,
	10 => 498,
);

# methods for calculation parameters

sub title			{ shift->{title}			}
sub with_sheet			{ shift->{with_sheet}			}
sub audio_size			{ shift->{audio_size}			}
sub vobsub_size			{ shift->{vobsub_size}			}
sub vcd_video_rate		{ shift->{vcd_video_rate}		}
sub max_svcd_sum_rate		{ shift->{max_svcd_sum_rate}		}
sub max_svcd_video_rate		{ shift->{max_svcd_video_rate}		}
sub max_video_rate		{ shift->{max_video_rate}		}

sub set_title			{ shift->{title}		= $_[1]	}
sub set_with_sheet		{ shift->{with_sheet}		= $_[1]	}
sub set_audio_size		{ shift->{audio_size}		= $_[1]	}
sub set_vobsub_size		{ shift->{vobsub_size}		= $_[1]	}
sub set_vcd_video_rate		{ shift->{vcd_video_rate}	= $_[1]	}
sub set_max_svcd_sum_rate	{ shift->{max_svcd_sum_rate}	= $_[1]	}
sub set_max_svcd_video_rate	{ shift->{max_svcd_video_rate}	= $_[1]	}
sub set_max_video_rate		{ shift->{max_video_rate}	= $_[1]	}

# methods for the result of calculation

sub video_bitrate		{ shift->{video_bitrate}		}
sub audio_bitrate		{ shift->{audio_bitrate}		}
sub vcd_reserve_bitrate		{ shift->{vcd_reserve_bitrate}		}
sub non_video_size		{ shift->{non_video_size}		}
sub target_size			{ shift->{target_size}			}
sub disc_size			{ shift->{disc_size}			}
sub video_size			{ shift->{video_size}			}
sub sheet			{ shift->{sheet}			}

sub set_video_bitrate		{ shift->{video_bitrate}	= $_[1]	}
sub set_audio_bitrate		{ shift->{audio_bitrate}	= $_[1]	}
sub set_vcd_reserve_bitrate	{ shift->{vcd_reserve_bitrate}	= $_[1]	}
sub set_non_video_size		{ shift->{non_video_size}	= $_[1]	}
sub set_target_size		{ shift->{target_size}		= $_[1]	}
sub set_disc_size		{ shift->{disc_size}		= $_[1]	}
sub set_video_size		{ shift->{video_size}		= $_[1]	}
sub set_sheet			{ shift->{sheet}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($title, $with_sheet) = @par{'title','with_sheet'};

	my $self = {
		title			=> $title,
		with_sheet		=> $with_sheet,
		sheet			=> [],
		vcd_video_rate		=> $VCD_VIDEO_RATE,
		max_svcd_sum_rate	=> $MAX_SVCD_SUM_RATE,
		max_svcd_video_rate	=> $MAX_SVCD_VIDEO_RATE,
		max_video_rate		=> $MAX_VIDEO_RATE,
	};
	
	return bless $self, $class;
}

sub add_audio_size {
	my $self = shift;
	my %par = @_;
	my ($bytes) = @par{'bytes'};

	$self->log (sprintf ("Add audio size: %.2f MB",$bytes  / 1024 / 1024));

	$self->set_audio_size ( $bytes + $self->audio_size );
	
	1;
}

sub add_vobsub_size {
	my $self = shift;
	my %par = @_;
	my ($bytes) = @par{'bytes'};
	
	$self->set_vobsub_size ( $bytes + $self->vobsub_size );
	
	1;
}

sub add_to_sheet {
	my $self = shift;
	return 1 if not $self->with_sheet;
	my ($href) = @_;
	push @{$self->sheet}, $href;
	1;
}

sub calculate_video_bitrate {
	my $self = shift;

	my $title     = $self->title;

	my $runtime   = $title->runtime;
	my $frames    = $title->frames;
	my $framerate = $title->tc_video_framerate;
	my $container = $title->tc_container;

	# reduce sum of frames (if a range was set)
	if ( $title->tc_video_bitrate_range ) {
		
		if ( $title->tc_start_frame ne '' or
		     $title->tc_end_frame ne '' ) {
		     	$frames = $title->tc_end_frame || $title->frames;
			$frames = $frames - $title->tc_start_frame
				     	if $title->has_vob_nav_file;
			$frames ||= $title->frames;
		}
		
		if ( $frames < 0 ) {
			$frames = $title->frames;
		}
	}
	
	# get sum of chapter frames (if chapter mode enabled)
	if ( $title->tc_use_chapter_mode eq 'select' ) {
		if ( not $title->real_actual_chapter ) {
			$frames = 0;
			my $chapters = $title->get_chapters;
			foreach my $chapter ( @{$chapters} ) {
				$frames += $title->chapter_frames->{$chapter};
			}
		} else {
			$frames = $title->chapter_frames->{$title->actual_chapter};
		}
	}

	# init sheet
	$self->set_sheet([]);
		
	if ( $frames and $framerate ) {	
		
		$self->add_to_sheet ({
			label    => __"Number of frames",
			operator => "",
			value    => $frames,
			unit     => "",
		});

		$self->add_to_sheet ({
			label    => __"Frames per second",
			operator => "/",
			value    => $framerate,
			unit     => "fps",
		});
	
		$runtime = $frames / $framerate;
		
		$self->add_to_sheet ({
			label    => __"Runtime",
			operator => "=",
			value    => $runtime,
			unit     => "s",
		});
	}
	
	
	# Target size
	my $target_size;
	if ( $title->tc_disc_cnt * $title->tc_disc_size == $title->tc_target_size ) {
		# Number of discs
		my $disc_cnt = $title->tc_disc_cnt;
		$self->add_to_sheet ({
			label    => __"Number of discs",
			operator => "",
			value    => $disc_cnt,
			unit     => "",
		});

		# Size of a disc
		my $disc_size = $title->tc_disc_size;
		$self->add_to_sheet ({
			label    => __"Disc size",
			operator => "*",
			value    => $disc_size,
			unit     => "MB",
		});

		$target_size = $disc_cnt * $disc_size;
	} else {
		$target_size = $title->tc_target_size;
	}

	$self->add_to_sheet ({
		label    => __"Target size",
		operator => "=",
		value    => $target_size,
		unit     => "MB",
	});

	# (S)VCD addition?
	if ( $container eq 'vcd' and $title->tc_disc_cnt * $title->tc_disc_size == $title->tc_target_size ) {
		my $addition = sprintf ("%.2f", (2324/2048-1) * $target_size);
		$self->add_to_sheet ({
			label    => __"VCD sector size addition (factor: 2324/2048)",
			operator => "+",
			value    => $addition,
			unit     => "MB",
		});
		$target_size += $addition;

		my $disc_overhead = sprintf ("%.2f", $VCD_DISC_OVERHEAD * $title->tc_disc_cnt / 1024 / 1024);
		$self->add_to_sheet ({
			label    => __"VCD per disc overhead (600 sectors)",
			operator => "-",
			value    => $disc_overhead,
			unit     => "MB",
		});
		$target_size -= $disc_overhead;

		$self->add_to_sheet ({
			label    => __"(X)(S)VCD/CVD target size",
			operator => "=",
			value    => $target_size,
			unit     => "MB",
		});
		
	}

	# audio tracks
	my $audio_size = 0;
	my $audio_bitrate;
	if ( $self->audio_size ) {
		# audio size is known already, no need to calculate it.
		$audio_size = sprintf ("%.2f", $self->audio_size / 1024 / 1024);
		$self->log (__x("Audio size is given with {audio_size} MB", audio_size => $audio_size));
		$self->add_to_sheet ({
			label    => __"Audio size",
			operator => "+",
			value    => $audio_size,
			unit     => "MB",
		});
	} else {
		foreach my $audio ( @{$title->audio_tracks} ) {
			next if $audio->tc_target_track == -1;

			my $bitrate = $audio->tc_bitrate;
			if ( $audio->tc_audio_codec eq 'vorbis' and
			     $audio->tc_vorbis_quality_enable ) {
			     	# derive a bitrate from vorbis quality setting
			     	$bitrate = $VORBIS_NOMINAL_BITRATES{int($audio->tc_vorbis_quality+0.5)};
			}

			my $track_size = $runtime * $bitrate * 1000 / 8 / 1024 / 1024;
			my $audio_overhead;
			$audio_overhead = $AVI_AUDIO_OVERHEAD * $frames / 1024 / 1024
				if $container eq 'avi';

			$track_size = sprintf ("%.2f", $track_size + $audio_overhead);

			my $comment;

			if ( $container eq 'avi' ) {
				$comment = " ".
					   __x("(incl. {avi_overhead} byte".
					       " AVI overhead per frame)",
					       avi_overhead => $AVI_AUDIO_OVERHEAD);
			}

			if ( $audio->tc_audio_codec eq 'vorbis' ) {
				if ( $audio->tc_vorbis_quality_enable ) {
					$comment = " ".__"(assume nominal bitrate for this quality)";
				} else {
					$comment = " ".__"(exact bitrate match assumed)";
				}
			}

			$self->add_to_sheet ({
				label    => __x("Audio track #{nr}",
						nr => $audio->tc_target_track).$comment,
				operator => "-",
				value    => $track_size,
				unit     => "MB",
			});

			$audio_size    += $track_size;
			$audio_bitrate += $bitrate;
		}
	}

	# AVI / OGG overhead
	my $container_overhead = 0;

	if ( $container eq 'avi' ) {
		$container_overhead = sprintf ("%.2f", $AVI_VIDEO_OVERHEAD * $frames / 1024 / 1024);

		$self->add_to_sheet ({
			label    => __x("AVI video overhead ({avi_overhead} bytes per frame)",
					avi_overhead => $AVI_VIDEO_OVERHEAD),
			operator => "-",
			value    => $container_overhead,
			unit     => "MB",
		});
		
	} elsif ( $container eq 'ogg' ) {
		$container_overhead = sprintf ("%.2f", $OGG_SIZE_OVERHEAD * $target_size);

		$self->add_to_sheet ({
			label    => __x("OGG overhead ({ogg_overhead} percent of target size)",
					ogg_overhead => $OGG_SIZE_OVERHEAD*100),
			operator => "-",
			value    => $container_overhead,
			unit     => "MB",
		});
	}

	# vobsub size
	my $vobsub_size = 0;
	
	if ( $self->vobsub_size ) {
		# vobsub size is known already, no need to calculate it.
		$vobsub_size = sprintf ("%.2f", $self->vobsub_size / 1024 / 1024);
		$self->add_to_sheet ({
			label    => __"vobsub size",
			operator => "-",
			value    => $vobsub_size,
			unit     => "MB",
		});
	} else {
		foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
			next if not $subtitle->tc_vobsub;
			$vobsub_size += 1;
			$self->add_to_sheet ({
				label    => __x("vobsub size subtitle #{nr}", nr => $subtitle->id),
				operator => "-",
				value    => 1,
				unit     => "MB",
			});
		}
	}

	# resulting video size
	my $non_video_size = $audio_size + $container_overhead + $vobsub_size;
	my $video_size     = $target_size - $non_video_size;

	$self->add_to_sheet ({
		label    => __"Space left for video",
		operator => "=",
		value    => $video_size,
		unit     => "MB",
	});

	# resulting video bitrate
	my $video_bitrate = int($video_size/$runtime/1000*1024*1024*8);

	my $comment = "(rounded)";
	if ( $video_bitrate > $self->max_video_rate ) {
		$video_bitrate = $self->max_video_rate;
		$comment = " ".__x("(too high, set to {max_video_rate})",
				   max_video_rate => $self->max_video_rate);
	}
	
	if ( $title->tc_video_codec =~ /^(X?SVCD|CVD|XVCD)$/ and
	     $video_bitrate + $audio_bitrate > $self->max_svcd_sum_rate ) {
		$video_bitrate = $self->max_svcd_sum_rate - $audio_bitrate;
		$comment = " ".__"(too high, limited)";
	}

	if ( $title->tc_video_codec =~ /^(X?SVCD|CVD|XVCD)$/ and
	     $video_bitrate > $self->max_svcd_video_rate ) {
		$video_bitrate = $self->max_svcd_video_rate;
		$comment = " ".__"(too high, limited)";
	}

	if ( $title->tc_video_codec =~ /^X?VCD$/ and
	     not $title->tc_video_bitrate_manual ) {
		$video_bitrate = $self->vcd_video_rate;
		$comment = " ".__"(VCD has fixed rate)";
	}

	if ( $title->tc_video_bitrate_manual ) {
		$video_bitrate = $title->tc_video_bitrate;
		$comment = " ".__"(manual setting)";
	}

	$self->add_to_sheet ({
		label    => __("Resulting video bitrate").$comment,
		operator => "~",
		value    => $video_bitrate,
		unit     => "kbit/s",
	});

	# calculate *real* video size, if bitrate has changed
	# after calculation (due to limits)
	$video_size = sprintf ("%.2f", $video_bitrate * $runtime * 1000 / 1024 / 1024 / 8);

	$self->add_to_sheet ({
		label    => __"Resulting video size",
		operator => "~",
		value    => $video_size,
		unit     => "MB",
	});

	# calculate real disc size (inkl. vcd addition)
	my $disc_size = $title->tc_disc_size;
	$disc_size = int($disc_size * $VCD_ADDITION_FACTOR -
			 	      $VCD_DISC_OVERHEAD / 1024 / 1024)
		if $title->tc_container eq 'vcd';

	# calculate vcd multiplex bitrate reserve
	my $vcd_reserve_bitrate =
		$audio_bitrate +
		int(($audio_bitrate + $video_bitrate)*0.02);

	$self->set_target_size    	( $target_size   	);
	$self->set_disc_size      	( $disc_size      	);
	$self->set_video_size     	( $video_size     	);
	$self->set_non_video_size 	( $non_video_size 	);
	$self->set_audio_bitrate  	( $audio_bitrate  	);
	$self->set_video_bitrate  	( $video_bitrate  	);
	$self->set_vcd_reserve_bitrate	( $vcd_reserve_bitrate	);

	return $video_bitrate;
}

1;
