# $Id: Title.pm,v 1.74 2002/05/14 22:15:31 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Title;

use base Video::DVDRip::Base;

use Video::DVDRip::Scan;
use Video::DVDRip::Probe;
use Video::DVDRip::PSU;

use Carp;
use strict;

use FileHandle;
use File::Path;
use File::Basename;
use File::Copy;

#------------------------------------------------------------------------
# These attributes are probed from the DVD
#------------------------------------------------------------------------

sub width			{ shift->probe_result->width		}
sub height			{ shift->probe_result->height		}
sub aspect_ratio		{ shift->probe_result->aspect_ratio	}
sub video_mode			{ shift->probe_result->video_mode	}
sub letterboxed			{ shift->probe_result->letterboxed	}
sub frames			{ shift->probe_result->frames		}
sub runtime			{ shift->probe_result->runtime		}
sub frame_rate			{ shift->probe_result->frame_rate	}
sub audio_size			{ shift->probe_result->audio_size	}
sub bitrates			{ shift->probe_result->bitrates		}
sub audio_tracks		{ shift->probe_result->audio_tracks	}
sub chapters			{ shift->probe_result->chapters		}
sub viewing_angles		{ shift->probe_result->viewing_angles	}

sub nr				{ shift->{nr}				}
sub size			{ shift->{size}				}
sub audio_channel		{ shift->{audio_channel}		}
sub scan_result			{ shift->{scan_result}			}
sub probe_result		{ shift->{probe_result}			}
sub preset			{ shift->{preset}			}
sub last_applied_preset		{ shift->{last_applied_preset}		}
sub preview_frame_nr		{ shift->{preview_frame_nr}		}
sub files			{ shift->{files}			}
sub actual_chapter		{ shift->{actual_chapter}		}
sub program_stream_units	{ shift->{program_stream_units}		}
sub bbox_min_x			{ shift->{bbox_min_x}			}
sub bbox_min_y			{ shift->{bbox_min_y}			}
sub bbox_max_x			{ shift->{bbox_max_x}			}
sub bbox_max_y			{ shift->{bbox_max_y}			}
sub chapter_frames		{ shift->{chapter_frames} ||= {}	}

sub set_nr			{ shift->{nr}			= $_[1] }
sub set_size			{ shift->{size}			= $_[1] }
sub set_audio_channel		{ shift->{audio_channel}	= $_[1] }
sub set_scan_result		{ shift->{scan_result}		= $_[1] }
sub set_probe_result		{ shift->{probe_result}		= $_[1] }
sub set_preset			{ shift->{preset}		= $_[1] }
sub set_last_applied_preset	{ shift->{last_applied_preset}	= $_[1]	}
sub set_preview_frame_nr	{ shift->{preview_frame_nr}	= $_[1] }
sub set_actual_chapter		{ shift->{actual_chapter}	= $_[1] }
sub set_program_stream_units	{ shift->{program_stream_units}	= $_[1] }
sub set_bbox_min_x		{ shift->{bbox_min_x}		= $_[1]	}
sub set_bbox_min_y		{ shift->{bbox_min_y}		= $_[1]	}
sub set_bbox_max_x		{ shift->{bbox_max_x}		= $_[1]	}
sub set_bbox_max_y		{ shift->{bbox_max_y}		= $_[1]	}

#------------------------------------------------------------------------
# These attributes must be specified by the user and are
# input parameters for the transcode process.
#------------------------------------------------------------------------

sub project			{ shift->{project}			}
sub tc_viewing_angle		{ shift->{tc_viewing_angle}      	}
sub tc_deinterlace		{ shift->{tc_deinterlace}      		}
sub tc_anti_alias		{ shift->{tc_anti_alias}      		}
sub tc_clip1_top		{ shift->{tc_clip1_top}			}
sub tc_clip1_bottom		{ shift->{tc_clip1_bottom}		}
sub tc_clip1_left		{ shift->{tc_clip1_left}		}
sub tc_clip1_right		{ shift->{tc_clip1_right}		}
sub tc_zoom_width		{ shift->{tc_zoom_width}		}
sub tc_zoom_height		{ shift->{tc_zoom_height}		}
sub tc_clip2_top		{ shift->{tc_clip2_top}			}
sub tc_clip2_bottom		{ shift->{tc_clip2_bottom}		}
sub tc_clip2_left		{ shift->{tc_clip2_left}		}
sub tc_clip2_right		{ shift->{tc_clip2_right}		}
sub tc_use_yuv_internal		{ shift->{tc_use_yuv_internal}  	}
sub tc_video_codec		{ shift->{tc_video_codec}		}
sub tc_video_af6_codec		{ shift->{tc_video_af6_codec}		}
sub tc_audio_codec		{ shift->{tc_audio_codec}		}
sub tc_video_bitrate		{ shift->{tc_video_bitrate}      	}
sub tc_audio_bitrate		{ shift->{tc_audio_bitrate}      	}
sub tc_video_framerate		{ shift->{tc_video_framerate}      	}
sub tc_fast_bisection		{ shift->{tc_fast_bisection}      	}

sub tc_target_size		{ shift->{tc_target_size}		}
sub tc_disc_cnt 	    	{ shift->{tc_disc_cnt}			}
sub tc_disc_size	    	{ shift->{tc_disc_size}			}
sub tc_start_frame	    	{ shift->{tc_start_frame}		}
sub tc_end_frame	    	{ shift->{tc_end_frame}			}
sub tc_fast_resize	    	{ shift->{tc_fast_resize}		}
sub tc_multipass	    	{ shift->{tc_multipass}			}
sub tc_title_nr	    		{ $_[0]->{tc_title_nr} || $_[0]->{nr}	}
sub tc_use_chapter_mode    	{ shift->{tc_use_chapter_mode}		}
sub tc_selected_chapters	{ shift->{tc_selected_chapters}		}
sub tc_options			{ shift->{tc_options}			}
sub tc_nice			{ shift->{tc_nice}			}
sub tc_preview			{ shift->{tc_preview}			}
sub tc_ac3_passthrough		{ shift->{tc_ac3_passthrough}		}
sub tc_mp3_quality		{ shift->{tc_mp3_quality}		}

sub set_project			{ shift->{project}		= $_[1] }
sub set_tc_viewing_angle	{ shift->{tc_viewing_angle}	= $_[1]	}
sub set_tc_deinterlace		{ shift->{tc_deinterlace}	= $_[1]	}
sub set_tc_anti_alias		{ shift->{tc_anti_alias}	= $_[1]	}
sub set_tc_clip1_top		{ shift->{tc_clip1_top}		= $_[1]	}
sub set_tc_clip1_bottom		{ shift->{tc_clip1_bottom}	= $_[1]	}
sub set_tc_clip1_left		{ shift->{tc_clip1_left}	= $_[1]	}
sub set_tc_clip1_right		{ shift->{tc_clip1_right}	= $_[1]	}
sub set_tc_zoom_width		{ shift->{tc_zoom_width}	= $_[1]	}
sub set_tc_zoom_height		{ shift->{tc_zoom_height}	= $_[1]	}
sub set_tc_clip2_top		{ shift->{tc_clip2_top}		= $_[1]	}
sub set_tc_clip2_bottom		{ shift->{tc_clip2_bottom}	= $_[1]	}
sub set_tc_clip2_left		{ shift->{tc_clip2_left}	= $_[1]	}
sub set_tc_clip2_right		{ shift->{tc_clip2_right}	= $_[1]	}
sub set_tc_use_yuv_internal	{ shift->{tc_use_yuv_internal}  = $_[1]	}
sub set_tc_video_codec		{ shift->{tc_video_codec}	= $_[1]	}
sub set_tc_video_af6_codec	{ shift->{tc_video_af6_codec}	= $_[1]	}
sub set_tc_audio_codec		{ shift->{tc_audio_codec}	= $_[1]	}
sub set_tc_video_bitrate	{ shift->{tc_video_bitrate}  	= $_[1]	}
sub set_tc_audio_bitrate	{ shift->{tc_audio_bitrate} 	= $_[1]	}
sub set_tc_video_framerate	{ shift->{tc_video_framerate} 	= $_[1]	}
sub set_tc_fast_bisection	{ shift->{tc_fast_bisection} 	= $_[1]	}

sub set_tc_target_size		{ shift->{tc_target_size}    	= $_[1]	}
sub set_tc_disc_cnt		{ shift->{tc_disc_cnt}    	= $_[1]	}
sub set_tc_disc_size		{ shift->{tc_disc_size}    	= $_[1]	}
sub set_tc_start_frame		{ shift->{tc_start_frame}    	= $_[1]	}
sub set_tc_end_frame		{ shift->{tc_end_frame}    	= $_[1]	}
sub set_tc_fast_resize		{ shift->{tc_fast_resize}    	= $_[1]	}
sub set_tc_multipass		{ shift->{tc_multipass}    	= $_[1]	}
sub set_tc_title_nr	    	{ shift->{tc_title_nr}    	= $_[1]	}
sub set_tc_use_chapter_mode 	{ shift->{tc_use_chapter_mode}	= $_[1]	}
sub set_tc_selected_chapters	{ shift->{tc_selected_chapters}	= $_[1] }
sub set_tc_options		{ shift->{tc_options}		= $_[1] }
sub set_tc_nice			{ shift->{tc_nice}		= $_[1] }
sub set_tc_preview		{ shift->{tc_preview}		= $_[1] }
sub set_tc_ac3_passthrough	{ shift->{tc_ac3_passthrough}	= $_[1] }
sub set_tc_mp3_quality		{ shift->{tc_mp3_quality}	= $_[1] }

sub tc_volume_rescale {
	my $self = shift;
	return $self->audio_tracks
		    ->[$self->audio_channel]
		    ->{tc_volume_rescale};
}

sub set_tc_volume_rescale {
	my $self = shift;
	my ($value) = @_;
	$self->audio_tracks
	     ->[$self->audio_channel]
	     ->{tc_volume_rescale} = $value;
}

sub vob_dir {
	my $self = shift; $self->trace_in;
	
	my $vob_dir;

	if ( $self->tc_use_chapter_mode ) {
		$vob_dir = sprintf("%s/%03d-C%03d",
			 $self->project->vob_dir,
			 $self->nr,
			($self->actual_chapter ||
			 $self->get_first_chapter || 1));

	} else {
		$vob_dir = sprintf("%s/%03d", $self->project->vob_dir, $self->nr);
	}
	
	return $vob_dir;
}

sub create_vob_dir {
	my $self = shift;
	
	my $vob_dir = $self->vob_dir;
	
	if ( not -d $vob_dir ) {
		mkpath ([ $vob_dir ], 0, 0755)
			or croak "Can't mkpath directory '$vob_dir'";
	}
	
	1;
}

sub avi_file {
	my $self = shift; $self->trace_in;

	my $video_codec = $self->tc_video_codec;
	my $ext = ($video_codec =~ /^S?VCD$/) ? "" : ".avi";

	if ( $self->tc_use_chapter_mode ) {
		return 	sprintf("%s/%03d/%s-%03d-C%03d$ext", 
			$self->project->avi_dir,
			$self->nr,
			$self->project->name,
			$self->nr,
			$self->actual_chapter
		);
	} else {
		return 	sprintf("%s/%03d/%s-%03d$ext",
			$self->project->avi_dir,
			$self->nr,
			$self->project->name,
			$self->nr
		);
	}
}

sub target_avi_file {
	my $self = shift; $self->trace_in;
	return $self->avi_file;
}

sub multipass_log_dir {
	my $self = shift;;
	return dirname($self->preview_filename);
}

sub create_avi_dir {
	my $self = shift;
	
	my $avi_dir = dirname $self->avi_file;

	if ( not -d $avi_dir ) {
		mkpath ([ $avi_dir ], 0, 0755)
			or croak "Can't mkpath directory '$avi_dir'";
	}
	
	1;
}

sub preview_filename {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	return 	sprintf("%s/%s-%03d-preview-%s.jpg",
		$self->project->snap_dir,
		$self->project->name,
		$self->nr,
		$type);
}

sub vob_nav_file {
	my $self = shift; $self->trace_in;
	
	my $file;
	if ( $self->tc_use_chapter_mode ) {
		$file =	sprintf("%s/%s-%03d-C%03d-nav.log",
			$self->project->snap_dir,
			$self->project->name,
			$self->nr,
			$self->actual_chapter);
	} else {
		$file =	sprintf("%s/%s-%03d-nav.log",
			$self->project->snap_dir,
			$self->project->name,
			$self->nr);
	}
	
	return $file;
}

sub new {
	my $class = shift;
	my %par = @_;
	my ($nr, $project) = @par{'nr','project'};

	my $self = {
		project	             => $project,
		nr                   => $nr,
		size                 => 0,
		files                => [],
		audio_channel        => 0,
		scan_result          => undef,
		probe_result         => undef,
		tc_clip1_top	     => 0,
		tc_clip1_bottom	     => 0,
		tc_clip1_left	     => 0,
		tc_clip1_right	     => 0,
		tc_clip2_top	     => 0,
		tc_clip2_bottom	     => 0,
		tc_clip2_left	     => 0,
		tc_clip2_right	     => 0,
		tc_selected_chapters => [],
		program_stream_units => [],
		chapter_frames       => {},
	};
	
	return bless $self, $class;
}

sub add_vob {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($file) = @par{'file'};
	
	$self->set_size ( $self->size + (-s $file) );
	push @{$self->files}, $file;
	
	1;
}

sub apply_preset {
	my $self = shift;
	my %par = @_;
	my ($preset) = @par{'preset'};

	return 1 if not $preset;
	
	$self->set_last_applied_preset ( $preset->name );
	
	if ( $preset->auto ) {
		$self->auto_adjust_clip_zoom (
			frame_size  => $preset->frame_size,
			fast_resize => $preset->tc_fast_resize,
		);
		return 1;
	}
	
	my $attributes = $preset->attributes;
	my $set_method;
	foreach my $attr ( @{$attributes} ) {
		$set_method = "set_$attr";
		$self->$set_method($preset->$attr());
	}
	
	1;
}

sub get_first_chapter {
	my $self = shift;
	
	my $chapter_mode = $self->tc_use_chapter_mode;
	return if not $chapter_mode;
	
	if ( $chapter_mode eq 'select' ) {
		my $chapters = $self->get_chapters;
		return $chapters->[0];
	} else {
		return 1;
	}
}

sub get_chapters {
	my $self = shift;

	my @chapters;
	if ( $self->tc_use_chapter_mode eq 'select' ) {
		@chapters = sort { $a <=> $b } @{$self->tc_selected_chapters || []};
	} else {
		@chapters = (1 .. $self->chapters);
	}

	return \@chapters;
}

sub calc_program_stream_units {
	my $self = shift;

	croak "You need at least transcode 0.6pre2" if $TC::VERSION < 600;

	my $vob_nav_file = $self->vob_nav_file;

	my $fh = FileHandle->new;
	open ($fh, $vob_nav_file) or
		croak "Can't read VOB navigation file '$vob_nav_file'";

	my $current_unit = 0;
	my (@program_stream_units, $unit, $frame, $last_frame);

	while (<$fh>) {
		($unit, $frame) = /(\d+)\s+(\d+)/;
		if ( $unit != $current_unit ) {
			push @program_stream_units,
				Video::DVDRip::PSU->new (
					nr       => $current_unit,
					frames   => $last_frame,
				);
			$current_unit = $unit;
		}
		$last_frame = $frame;
	}
	
	if ( $last_frame != 0 ) {
		push @program_stream_units,
			Video::DVDRip::PSU->new (
				nr       => $current_unit,
				frames   => $last_frame,
			);
	}
	
	close $fh;

	$self->set_program_stream_units (\@program_stream_units);

	$self->log ("Program stream units calculated");

	1;
}

sub auto_adjust_clip_zoom {
	my $self = shift;
	my %par = @_;
	my  ($frame_size, $fast_resize) =	# frame_size  = 'big' or 'small'
	@par{'frame_size','fast_resize'};	# fast_resize = 1 or 0

	croak "invalid parameter for frame_size ('$frame_size')"
		if not $frame_size =~ /^(big|medium|small)$/;

	# frame geometry
	my $width      = $self->width;
	my $height     = $self->height;

	# bounding box
	my $min_x  = $self->bbox_min_x;
	my $min_y  = $self->bbox_min_y;
	my $max_x  = $self->bbox_max_x;
	my $max_y  = $self->bbox_max_y;

	# aspect ratio
	my $aspect_ratio = $self->aspect_ratio;	# 4:3 or 16:9

	my ($clip1_top, $clip1_bottom, $clip1_left, $clip1_right) = (0, 0, 0, 0);
	my ($clip2_top, $clip2_bottom, $clip2_left, $clip2_right) = (0, 0, 0, 0);
	my ($zoom_width, $zoom_height) = (undef, undef);

	# width and height of clip area
	my $bb_width  = ($max_x - $min_x) + 1;
	my $bb_height = ($max_y - $min_y) + 1;

	# The suggestion depends on $frame_size and $fast_resize
	if ( not $fast_resize ) {
		# we predefine clip1
		$clip1_top    = $min_y;
		$clip1_bottom = $height - $max_y;
		$clip1_left   = $min_x;
		$clip1_right  = $width - $max_x;

		if ( $aspect_ratio eq '4:3' ) {
			# resizing to correct aspect ratio
			# (increase width with factor 1.3333333 / 1.25
			#  which is exactly 1024 / 720)
			$zoom_width   = $bb_width * 4/3 / 1.25;
			$zoom_height  = $bb_height;
		} else {
			# resizing to correct aspect ratio
			# (increase width with factor 1.777777 / 1.25
			#  which is exactly 1024 / 720)
			$zoom_width   = $bb_width * 1024 / 720;
			$zoom_height  = $bb_height;
		}
		
		if ( $frame_size eq 'big' ) {
			# do not reduce
			$zoom_width  = int ($zoom_width);
			$zoom_height = int ($zoom_height);

		} elsif ( $frame_size eq 'medium' ) {
			# reduce 1/4
			$zoom_width  = int( $zoom_width  * 0.75 );
			$zoom_height = int( $zoom_height * 0.75 );
		} else {
			# reduce 1/2
			$zoom_width  = int( $zoom_width  * 0.5 );
			$zoom_height = int( $zoom_height * 0.5 );
		}

		# odd values are bad for 2nd clipping
		++$zoom_height if $zoom_height % 2;
		++$zoom_width  if $zoom_width % 2;

		# finally use 2nd clipping to get width/height
		# divisible by 16
		my $rest;
		if ( $rest = $zoom_width % 16 ) {
			if ( $rest % 2 == 0 ) {
				$clip2_left = $clip2_right = $rest / 2;
			} else {
				$clip2_left  = $rest / 2 - 0.5;
				$clip2_right = $rest / 2 + 0.5;
			}
		}
		if ( $rest = $zoom_height % 16 ) {
			if ( $rest % 2 == 0 ) {
				$clip2_top = $clip2_bottom = $rest / 2;
			} else {
				$clip2_top    = $rest / 2 - 0.5;
				$clip2_bottom = $rest / 2 + 0.5;
			}
		}

	} else {
		# first we preset good values for resizing / aspect ratio
		# After that we apply the cropping to 2nd clip, taking
		# resize ration in account
		
		my %presets = (
			"16:9" => {
				"big" => {
					clip1_left   => 0,
					clip1_right  => 0,
					clip1_top    => 0,
					clip1_bottom => 0,
					zoom_width   => 720,
					zoom_height  => 408,
				},
				"medium" => {
					clip1_left   => 0,
					clip1_right  => 0,
					clip1_top    => 0,
					clip1_bottom => 0,
					zoom_width   => 640,
					zoom_height  => 360,
				},
				"small" => {
					clip1_left   => 0,
					clip1_right  => 0,
					clip1_top    => 0,
					clip1_bottom => 0,
					zoom_width   => 512,
					zoom_height  => 288,
				},
			},
			"4:3"  => {
				"big" => {
					clip1_left   => 8,
					clip1_right  => 8,
					clip1_top    => 0,
					clip1_bottom => 0,
					zoom_width   => 704,
					zoom_height  => 544,
				},
				"medium" => {
					clip1_left   => 8,
					clip1_right  => 8,
					clip1_top    => 0,
					clip1_bottom => 0,
					zoom_width   => 528,
					zoom_height  => 408,
				},
				"small" => {
					clip1_left   => 8,
					clip1_right  => 8,
					clip1_top    => 0,
					clip1_bottom => 0,
					zoom_width   => 352,
					zoom_height  => 272,
				},
			},
		);

		my $preset = $presets{$aspect_ratio}->{$frame_size};

		($clip1_top, $clip1_bottom, $clip1_left, $clip1_right,
		 $zoom_width, $zoom_height) = @$preset{
		 'clip1_top','clip1_bottom','clip1_left','clip1_right',
		 'zoom_width','zoom_height'};
		
		my $resize_width_ratio  = ($width-$clip1_left-$clip1_left)/$zoom_width;
		my $resize_height_ratio = ($height-$clip1_top-$clip1_bottom)/$zoom_height;

		$clip2_left   = ($min_x - $clip1_left) / $resize_width_ratio;
		$clip2_left   = 0 if $clip2_left < 0;
		$clip2_left   = 1+int($clip2_left) if int($clip2_left) != $clip2_left;
		$clip2_right  = ($width - $max_x-1 - $clip1_right) / $resize_width_ratio;
		$clip2_right  = 0 if $clip2_right < 0;
		$clip2_right  = 1+int($clip2_right) if int($clip2_right) != $clip2_right;
		$clip2_top    = ($min_y - $clip1_top) / $resize_height_ratio;
		$clip2_top    = 0 if $clip2_top < 0;
		$clip2_top    = 1+int($clip2_top) if int($clip2_top) != $clip2_top;
		$clip2_bottom = ($height - $max_y-1 - $clip1_bottom) / $resize_height_ratio;
		$clip2_bottom = 0 if $clip2_bottom < 0;
		$clip2_bottom = 1+int($clip2_bottom) if int($clip2_bottom) != $clip2_bottom;

		my $final_width  = $zoom_width  - $clip2_left - $clip2_right;
		my $final_height = $zoom_height - $clip2_top  - $clip2_bottom;

		# finally use 2nd clipping to get width/height
		# dividable by 16
		my $rest;
		if ( $rest = $final_width % 16 ) {
			if ( $rest % 2 == 0 ) {
				$clip2_left  += $rest / 2;
				$clip2_right += $rest / 2;
			} else {
				$clip2_left  += $rest / 2 - 0.5;
				$clip2_right += $rest / 2 + 0.5;
			}
		}
		if ( $rest = $final_height % 16 ) {
			if ( $rest % 2 == 0 ) {
				$clip2_top    += $rest / 2;
				$clip2_bottom += $rest / 2;
			} else {
				$clip2_top    += $rest / 2 - 0.5;
				$clip2_bottom += $rest / 2 + 0.5;
			}
		}

	}

	# height clipping must not be odd
	if ( $clip2_top % 2 and $clip2_bottom > $clip2_top ) {
		++$clip2_top;
		--$clip2_bottom;
	} elsif ( $clip2_top % 2 and $clip2_bottom < $clip2_top ) {
		--$clip2_top;
		++$clip2_bottom;
	}

	($zoom_width, $zoom_height) = (undef,undef)
		if $zoom_width  == ($width  - $clip1_left - $clip2_left) and
		   $zoom_height == ($height - $clip1_top  - $clip2_bottom);

	$self->set_tc_clip1_left   ( $clip1_left );
	$self->set_tc_clip1_right  ( $clip1_right );
	$self->set_tc_clip1_top    ( $clip1_top );
	$self->set_tc_clip1_bottom ( $clip1_bottom );
	$self->set_tc_clip2_left   ( $clip2_left );
	$self->set_tc_clip2_right  ( $clip2_right );
	$self->set_tc_clip2_top    ( $clip2_top );
	$self->set_tc_clip2_bottom ( $clip2_bottom );
	$self->set_tc_zoom_width   ( $zoom_width );
	$self->set_tc_zoom_height  ( $zoom_height );
	$self->set_tc_fast_resize  ( $fast_resize );

	1;
}

sub get_effective_ratio {
	my $self = shift;
	my %par = @_;
	my ($type) = @par{'type'};	# clip1, zoom, clip2
	
	my $width        = $self->width;
	my $height       = $self->height;
	my $clip1_ratio  = $width/$height;

	my $from_width  = $width-$self->tc_clip1_left-$self->tc_clip1_right;
	my $from_height = $height-$self->tc_clip1_top-$self->tc_clip1_bottom;

	return ($from_width, $from_height, $clip1_ratio) if $type eq 'clip1';

	my $zoom_width  = $self->tc_zoom_width  || $width;
	my $zoom_height = $self->tc_zoom_height || $height;
	my $zoom_ratio = ($zoom_width/$zoom_height) * ($width/$height) / ($from_width/$from_height);

	return ($zoom_width, $zoom_height, $zoom_ratio) if $type eq 'zoom';

	my $clip2_width  = $zoom_width  - $self->tc_clip2_left - $self->tc_clip2_right;
	my $clip2_height = $zoom_height - $self->tc_clip2_top  - $self->tc_clip2_bottom;

	return ($clip2_width, $clip2_height, $zoom_ratio);


#	return ($self->aspect_ratio eq '16:9' ? 16/9 : 4/3)
#		if $from_width == 0 or $from_height == 0;

}

#---------------------------------------------------------------------
# Methods for Ripping
#---------------------------------------------------------------------

sub is_ripped {
	my $self = shift;
	
	my $name = $self->project->name;

	if ( not $self->tc_use_chapter_mode ) {
		my $vob_dir = $self->vob_dir;
		return -f "$vob_dir/$name-001.vob";
	}
	
	my $chapters = $self->get_chapters;
	
	my $vob_dir;
	foreach my $chapter ( @{$chapters} ) {
		$self->set_actual_chapter($chapter);
		$vob_dir = $self->vob_dir;
		$self->set_actual_chapter(undef);
		return if not -f "$vob_dir/$name-001.vob";
	}
	
	return 1;
}

sub get_rip_command {
	my $self = shift; $self->trace_in;

	my $nr           = $self->tc_title_nr;
	my $name         = $self->project->name;
	my $dvd_device   = $self->project->dvd_device;
	my $vob_dir      = $self->vob_dir;
	my $vob_nav_file = $self->vob_nav_file;

	$self->create_vob_dir;

	my $chapter =
		$self->tc_use_chapter_mode ? $self->actual_chapter : "-1";

	my $angle = $self->tc_viewing_angle || 1;

	# version 0.6.0pre has tcdemux -W which can be used
	# for calculating the progress bar and for cluster
	# transcoding. The splitpipe -f switch enables piping
	# data through tcdemux.
	my $f = $TC::VERSION >= 600 ? "-f $vob_nav_file" : "";

	my $command = "rm -f $vob_dir/$name-???.vob;\n".
	           "tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device ".
	           "| splitpipe $f 1024 $vob_dir/$name vob >/dev/null";

	return $command;
}

sub rip {
	my $self = shift; $self->trace_in;

	$self->system (
		command => $self->get_rip_command,
	);

	$self->set_chapter_length if $self->tc_use_chapter_mode;
	
	1;
}

sub rip_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($callback) = @par{'callback'};
	
	$self->popen (
		command  => $self->get_rip_command,
		callback => $callback,
	);
	
	$self->set_chapter_length if $self->tc_use_chapter_mode;

	1;
}

sub rip_async_start {
	my $self = shift; $self->trace_in;
	
	return $self->popen (
		command => $self->get_rip_command,
	);
}

sub rip_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_rip_command.
			$output;

	my $rc = close $fh;
	croak ($message) if $?;

	$self->set_chapter_length if $self->tc_use_chapter_mode;

	1;
}

sub set_chapter_length {
	my $self = shift; $self->trace_in;
	
	my $chapter      = $self->actual_chapter;
	my $vob_nav_file = $self->vob_nav_file;

	my $fh = FileHandle->new;
	open ($fh, $vob_nav_file) or
		croak "Can't read VOB navigation file '$vob_nav_file'";

	my ($frames, $block_offset, $frame_offset);
	++$frames while <$fh>;
	close $fh;
	
	$self->chapter_frames->{$chapter} = $frames;

	1;
}

#---------------------------------------------------------------------
# Methods for Scanning
#---------------------------------------------------------------------

sub get_scan_command {
	my $self = shift; $self->trace_in;

	my $vob_dir       = $self->vob_dir;
	my $audio_channel = $self->audio_channel;

	return "cat $vob_dir/* ".
	       "| tcextract -a $audio_channel -x ac3 -t vob ".
	       "| tcdecode -x ac3 ".
	       "| tcscan -x pcm";
}

sub scan {
	my $self = shift; $self->trace_in;

	my $output = $self->system (
		command => $self->get_scan_command,
	);
	
	$self->analyze_scan_output (
		output => $output
	);
	
	1;
}

sub scan_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($callback) = @par{'callback'};
	
	my $output = $self->popen (
		command => $self->get_scan_command,
		callback => $callback,
		catch_output => 1,
	);
	
	$self->analyze_scan_output (
		output => $output
	);

	1;
}

sub scan_async_start {
	my $self = shift; $self->trace_in;
	
	return $self->popen (
		command => $self->get_scan_command,
	);
}

sub scan_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_scan_command.
			$output;

	close $fh;
	croak ($message) if $?;

	$self->analyze_scan_output (
		output => $output
	);
	
	1;
}

sub analyze_scan_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};

	$output =~ s/^.*?--splitpipe-finished--\n//s;

	my $scan_result = Video::DVDRip::Scan->analyze (
		scan_output => $output,
	);

	$self->audio_tracks
	     ->[$self->audio_channel]
	     ->{scan_result} = $scan_result;

	$self->set_tc_volume_rescale ( $scan_result->volume_rescale );

	1;
}

#---------------------------------------------------------------------
# Methods for Ripping and Scanning
#---------------------------------------------------------------------

sub get_rip_and_scan_command {
	my $self = shift; $self->trace_in;

	my $nr            = $self->tc_title_nr;
	my $audio_channel = $self->audio_channel;
	my $name          = $self->project->name;
	my $dvd_device    = $self->project->dvd_device;
	my $vob_dir    	  = $self->vob_dir;
	my $vob_nav_file  = $self->vob_nav_file;

	$self->create_vob_dir;

	my $chapter =
		$self->tc_use_chapter_mode ? $self->actual_chapter : "-1";

	my $angle = $self->tc_viewing_angle || 1;

	# version 0.6.0pre has tcdemux -W which can be used
	# for calculating the progress bar and for cluster
	# transcoding. The splitpipe -f switch enables piping
	# data through tcdemux.
	my $f = $TC::VERSION >= 600 ? "-f $vob_nav_file" : "";

	my $command =
	       "rm -f $vob_dir/$name-???.vob;\n".
	       "tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device ".
	       "| splitpipe $f 1024 $vob_dir/$name vob ".
	       "| tcextract -a $audio_channel -x ac3 -t vob ".
	       "| tcdecode -x ac3 ".
	       "| tcscan -x pcm";

	return $command;
}

sub rip_and_scan {
	my $self = shift; $self->trace_in;

	my $output = $self->system (
		command => $self->get_rip_and_scan_command,
	);

	$self->analyze_scan_output (
		output => $output
	);

	$self->set_chapter_length if $self->tc_use_chapter_mode;
	
	1;
}

sub rip_and_scan_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($callback) = @par{'callback'};
	
	my $output = $self->popen (
		command      => $self->get_rip_and_scan_command,
		callback     => $callback,
		catch_output => 1,
	);

	$self->analyze_scan_output (
		output => $output
	);

	$self->set_chapter_length if $self->tc_use_chapter_mode;

	1;
}

sub rip_and_scan_async_start {
	my $self = shift; $self->trace_in;
	
	return $self->popen (
		command   => $self->get_rip_and_scan_command,
#		line_mode => 1,
	);
}

sub rip_and_scan_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_rip_and_scan_command.
			$output;

	close $fh;
	croak ($message) if $?;

	$self->analyze_scan_output (
		output => $output
	);
	
	$self->set_chapter_length if $self->tc_use_chapter_mode;

	1;
}

#---------------------------------------------------------------------
# Methods for Probing DVD
#---------------------------------------------------------------------

sub get_probe_command {
	my $self = shift; $self->trace_in;
	
	my $nr            = $self->tc_title_nr;
	my $dvd_device    = $self->project->dvd_device;

	return "tcprobe -i $dvd_device -T $nr";
}

sub probe {
	my $self = shift; $self->trace_in;
	
	my $dvd_device = $self->project->dvd_device;

	my $output = $self->system (
		command => $self->get_probe_command
	);
	
	$self->analyze_probe_output (
		output => $output
	);
	
	1;
}

sub probe_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($callback) = @par{'callback'};
	
	my $output = $self->popen (
		command => $self->get_probe_command,
		callback => $callback,
		catch_output => 1,
	);
	
	$self->analyze_probe_output (
		output => $output
	);

	1;
}

sub probe_async_start {
	my $self = shift; $self->trace_in;
	
	return $self->popen (
		command => $self->get_probe_command,
	);
}

sub probe_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	my $message =   "Error executing:\n\n".
			$self->get_probe_command.
			"\n\nOutput was:\n\n".
			$output;

	close $fh;
	croak ($message) if $?;

	$self->analyze_probe_output (
		output => $output
	);
	
	1;
}

sub analyze_probe_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};



	$self->set_probe_result (
		Video::DVDRip::Probe->analyze (
			probe_output => $output,
		)
	);

	$self->set_audio_channel(0);

	1;
}

#---------------------------------------------------------------------
# Methods for probing detailed audio information
#---------------------------------------------------------------------

sub get_probe_audio_command {
	my $self = shift; $self->trace_in;
	
	my $nr      = $self->tc_title_nr;
	my $vob_dir = $self->vob_dir;

	return "tcprobe -i $vob_dir";
}

sub probe_audio {
	my $self = shift; $self->trace_in;
	
	my $output = $self->system (
		command => $self->get_probe_audio_command
	);
	
	$self->analyze_probe_audio_output (
		output => $output
	);
	
}

sub analyze_probe_audio_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};

	$self->probe_result->analyze_audio (
		probe_output => $output
	);

	1;
}

#---------------------------------------------------------------------
# Methods for Transcoding
#---------------------------------------------------------------------

sub suggest_transcode_options {
	my $self = shift; $self->trace_in;

	$self->set_tc_viewing_angle ( 1 );
	$self->set_tc_use_yuv_internal ( 1 );
	$self->set_tc_video_codec ( "divx4" );
	$self->set_tc_audio_codec ( "" );
	$self->set_tc_audio_bitrate ( 128 );
	$self->set_tc_ac3_passthrough ( 0 );
	$self->set_tc_mp3_quality ( 0 );
	$self->set_tc_multipass ( 1 );
	$self->set_tc_target_size ( 1400 );
	$self->set_tc_disc_size ( 700 );
	$self->set_tc_disc_cnt ( 2 );
	$self->set_tc_video_framerate (
		$self->video_mode eq 'pal' ? 25 : 23.976
	);
	$self->calc_video_bitrate;
	$self->set_preset ( "auto_medium_fast" );

	1;
}

sub calc_video_bitrate {
	my $self = shift;

	my $video_codec     = $self->tc_video_codec;

	if ( $video_codec eq 'VCD' ) {
		$self->set_tc_video_bitrate ( 1152 );
		$self->set_tc_audio_bitrate ( 224 );
		$self->set_tc_ac3_passthrough ( 0 );
		$self->set_tc_multipass ( 0 );
		return 1;
	}
	
	if ( $video_codec eq 'SVCD' ) {
		$self->set_tc_ac3_passthrough ( 0 );
		$self->set_tc_multipass ( 0 );
	}

	my $ac3_passthrough = $self->tc_ac3_passthrough;

	if ( $ac3_passthrough ) {
		$self->set_tc_audio_bitrate(
			$self->audio_tracks
			     ->[$self->audio_channel]
			     ->{bitrate}
		);
	}

	my $target_size   = $self->tc_target_size;
	my $frames        = $self->frames;
	my $fps           = $self->frame_rate;
	my $audio_bitrate = $self->tc_audio_bitrate;

	my $runtime = $frames / $fps;
	my $audio_size = int($runtime * $audio_bitrate / 1024 / 8);
	my $video_size = $target_size - $audio_size;

	my $video_bitrate = int($video_size/$runtime/1000*1024*1024*8);
	$video_bitrate = 6000 if $video_bitrate > 6000;
	$video_bitrate = 2600 if $video_bitrate > 2600 and
				 $video_codec eq 'SVCD';
	$self->set_tc_video_bitrate ( $video_bitrate );

	1;
}

sub get_transcode_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($pass) = @par{'pass'};

	my $nr       = $self->nr;
	my $avi_file = $self->avi_file;

	my $audio_info = $self->audio_tracks
			      ->[$self->audio_channel];

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $mpeg = 0;
	$mpeg = "svcd" if $self->tc_video_codec =~ /^SVCD$/;
	$mpeg = "vcd"  if $self->tc_video_codec =~ /^VCD$/;

	my $command =
		$nice.
		"transcode".
		" -i ".$self->vob_dir.
		" -a ".$self->audio_channel;
	
	if ( not $mpeg ) {
		$command .=
			" -w ".int($self->tc_video_bitrate).",250,100";
	} elsif ( $mpeg eq 'svcd' ) {
		$command .=
			" -w ".int($self->tc_video_bitrate)
				if $self->tc_video_bitrate;
	}

	if ( $self->tc_use_chapter_mode and $TC::VERSION < 600 ) {
		$command .= qq{ -J skip="0-2" };
	}
	
	if ( $self->tc_start_frame ne '' or
	     $self->tc_end_frame ne '' ) {
		my $start_frame = $self->tc_start_frame;
		my $end_frame   = $self->tc_end_frame;
		$start_frame ||= 0;
		$end_frame   ||= $self->frames;
		$command .= " -c $start_frame-$end_frame";
	}

	if ( $mpeg ) {
		$command .= " -F 5" if $mpeg eq 'svcd';
		$command .= " -F 1" if $mpeg eq 'vcd';
		if ( $mpeg eq 'svcd' ) {
			if ( $self->aspect_ratio eq '16:9' ) {
				# 16:9
				$command .= " --export_asr 3";
			} else {
				# 4:3
				$command .= " --export_asr 2";
			}
		} else {
			$command .= " --export_asr 2";
		}
	} else {
		$command .= " -F ".$self->tc_video_af6_codec
			if $self->tc_video_af6_codec ne '';
	}

	$command .= " -d" if $audio_info->{type} eq 'lpcm';

	if ( $TC::VERSION < 600 ) {
		$command .= " -b ".$self->tc_audio_bitrate
			if $self->tc_audio_bitrate ne '';
	} else {
		if ( $mpeg ) {
			$command .= " -b ".
				$self->tc_audio_bitrate;
		} else {
			$command .= " -b ".
				$self->tc_audio_bitrate.",0,".
				$self->tc_mp3_quality;
		}
	}

	if ( $self->tc_ac3_passthrough ) {
		$command .=
			" -A -N ".$audio_info->{tc_option_n};
	} else {
		$command .= " -s ".$audio_info->{tc_volume_rescale}
			if $audio_info->{tc_volume_rescale} != 0 and 
			   $audio_info->{type} ne 'lpcm';
	}

	$command .= " -V "
		if $self->tc_use_yuv_internal;
	$command .= " -C ".$self->tc_anti_alias
		if $self->tc_anti_alias;
	$command .= " -I ".$self->tc_deinterlace
		if $self->tc_deinterlace;

	if ( $TC::VERSION < 600 ) {
		$command .= " -f ".$self->tc_video_framerate
			if $self->tc_video_framerate;
	} elsif ( $self->tc_video_framerate ) {
		my $fr = $self->tc_video_framerate;
		$fr = "24,1" if $fr == 23.976;
		$fr = "30,4" if $fr == 29.97;
		$command .= " -f $fr";
	}

	if ( $self->video_mode eq 'ntsc' ) {
		$command .= " -g 720x480 -M 2";
	}

	$command .= " -J preview=xv" if $self->tc_preview;

	my $clip1 = $self->tc_clip1_top.",".
		    $self->tc_clip1_left.",".
		    $self->tc_clip1_bottom.",".
		    $self->tc_clip1_right;

	$command .= " -j $clip1"
		if $clip1 =~ /^-?\d+,-?\d+,-?\d+,-?\d+$/ and $clip1 ne '0,0,0,0';

	my $clip2 = $self->tc_clip2_top.",".
		    $self->tc_clip2_left.",".
		    $self->tc_clip2_bottom.",".
		    $self->tc_clip2_right;

	$command .= " -Y $clip2"
		if $clip2 =~ /^-?\d+,-?\d+,-?\d+,-?\d+$/ and $clip2 ne '0,0,0,0';

	if ( $self->tc_fast_bisection ) {
		$command .= " -r 2,2";

	} elsif ( not $self->tc_fast_resize ) {
		my $zoom = $self->tc_zoom_width."x".$self->tc_zoom_height;
		$command .= " -Z $zoom"
			if $zoom =~ /^\d+x\d+$/;

	} else {

		my $multiple_of = $TC::VERSION < 600 ? 32 : 8;

		my ($width_n, $height_n, $err_div32, $err_shrink_expand) =
			$self->get_fast_resize_options;

		if ( $err_div32 ) {
			croak "When using fast resize: Clip1 and Zoom size must be divisible by $multiple_of";
		}

		if ( $err_shrink_expand ) {
			croak "When using fast resize: Width and height must both shrink or expand";
		}

		if ( $width_n * $height_n >= 0 ) {
			if ( $width_n > 0 or $height_n > 0 ) {
				$command .= " -X $height_n,$width_n";
				$command .= ",$multiple_of" if $multiple_of != 32;
			} else {
				$width_n  = abs($width_n);
				$height_n = abs($height_n);
				$command .= " -B $height_n,$width_n";
				$command .= ",$multiple_of" if $multiple_of != 32;
			}
		}
	}

	if ( $self->tc_multipass ) {
		my $dir = $self->multipass_log_dir;
		$command = "mkdir -m 0775 -p '$dir'; cd $dir; $command";
		$command .= " -R $pass";

		if ( $pass == 1 ) {
			$command .= " -x vob,null -o /dev/null";
			$command .= " -y ".$self->tc_video_codec.",null";
		}
	}
	
	if ( not $self->tc_multipass or $pass == 2 ) {
		$command .= " -x vob";
		$command .= " -o $avi_file";
		
		if ( $mpeg ) {
			$command .= " -y mpeg2enc,mp2enc -E 44100";
		} else {
			$command .= " -y ".$self->tc_video_codec;
		}
	}

	$self->create_avi_dir;

	$command = $self->combine_command_options (
		cmd      => "transcode",
		cmd_line => $command,
		options  => $self->tc_options,
	) if $self->tc_options =~ /\S/;

	return $command;
}

sub get_fast_resize_options {
	my $self = shift;

	my $multiple_of = $TC::VERSION < 600 ? 32 : 8;

	my $width = $self->width - $self->tc_clip1_left
				 - $self->tc_clip1_right;
	my $height = $self->height - $self->tc_clip1_top
				   - $self->tc_clip1_bottom;

	my $zoom_width  = $self->tc_zoom_width;
	my $zoom_height = $self->tc_zoom_height;

	my $width_n  = ($zoom_width  - $width)  / $multiple_of;
	my $height_n = ($zoom_height - $height) / $multiple_of;

	my ($err_div32, $err_shrink_expand);

	$self->print_debug("width_n=$width_n width=$width width \% $multiple_of = ", $width % $multiple_of);
	$self->print_debug("height_n=$height_n height=$height height \% $multiple_of = ", $height % $multiple_of);

	if ( ($width_n != 0 and ( $zoom_width % $multiple_of != 0 or $width % $multiple_of != 0) ) or
	     ($height_n != 0 and ( $zoom_height % $multiple_of != 0 or $height % $multiple_of != 0 ) ) ) {
		$err_div32 = 1;
	}

	if ( $width_n * $height_n < 0 ) {
		$err_shrink_expand = 1;
	}

	return ($width_n, $height_n, $err_div32, $err_shrink_expand);
}

sub transcode {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($pass) = @par{'pass'};

	$self->system (
		command => $self->get_transcode_command ( pass => $pass ),
	);
	
	1;
}

sub transcode_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($callback, $pass) = @par{'callback','pass'};

	$self->popen (
		command  => $self->get_transcode_command ( pass => $pass ),
		callback => $callback,
	);
	
	1;
}

sub transcode_async_start {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($pass) = @par{'pass'};

	return $self->popen (
		command => $self->get_transcode_command ( pass => $pass ),
	);
}

sub transcode_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_transcode_command.
			$output;

	close $fh;
	croak ($message) if $?;

	1;
}

#---------------------------------------------------------------------
# Methods for MPEG multiplexing
#---------------------------------------------------------------------

sub get_mplex_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($split) = @par{'split'};

	my $video_codec = $self->tc_video_codec;

	my $avi_file = $self->target_avi_file;
	my $size     = $self->tc_disc_size;

	my $mplex_f  = $video_codec eq 'SVCD' ? 4 : 1;
	my $mplex_v  = $video_codec eq 'SVCD' ? "-V" : "";
	my $vext     = $video_codec eq 'SVCD' ? 'm2v' : 'm1v';

	my $split_option = $split ? "-S $size -M " : "";
	my $target_file  = $split ? "$avi_file-%d.mpg" : "$avi_file.mpg";

	my $command =
		"mplex -f $mplex_f $mplex_v $split_option ".
		"-o $target_file $avi_file.$vext $avi_file.mpa";
	
	return $command;
}

sub mplex_async_start {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($split) = @par{'split'};
	
	return $self->popen (
		command => $self->get_mplex_command ( split => $split ),
	);
}

sub mplex_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output, $split) = @par{'fh','output','split'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_mplex_command ( split => $split ).
			$output;

	close $fh;
	croak ($message) if $?;

	1;
}

#---------------------------------------------------------------------
# Methods for AVI Splitting
#---------------------------------------------------------------------

sub get_split_command {
	my $self = shift; $self->trace_in;

	my $avi_file = $self->target_avi_file;
	my $size     = $self->tc_disc_size;

	my $avi_dir = dirname $avi_file;
	$avi_file   = basename $avi_file;

	my $command = "cd $avi_dir; avisplit -s $size -i $avi_file";
	
	return $command;
}

sub split {
	my $self = shift; $self->trace_in;

	my $command = $self->get_split_command;
	return if not $command;

	$self->system (
		command => $command
	);
	
	$self->rename_avi_files;
	
	return 1;
}

sub rename_avi_files {
	my $self = shift; $self->trace_in;
	
	my $avi_file = $self->avi_file;
	
	my $new_file;
	foreach my $file ( glob ("$avi_file-*") ) {
		$new_file = $file;
		$new_file =~ s/\.avi-(\d+)$/"-".($1+1).".avi"/e;
		rename ($file, $new_file);
	}
	
	1;
}

sub split_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($callback) = @par{'callback'};

	my $command = $self->get_split_command;
	return if not $command;

	$self->popen (
		command => $command,
		callback => $callback,
	);
	
	$self->rename_avi_files;
	
	1;
}

sub split_async_start {
	my $self = shift; $self->trace_in;
	
	my $command = $self->get_split_command;
	return if not $command;

	return $self->popen (
		command => $command,
	);
}

sub split_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_split_command.
			$output;

	close $fh;
	croak ($message) if $?;

	$self->rename_avi_files;

	1;
}

#---------------------------------------------------------------------
# Methods for taking Snapshots
#---------------------------------------------------------------------

sub snapshot_filename	  	{ shift->{snapshot_filename}  	 	}
sub set_snapshot_filename  	{ shift->{snapshot_filename}  = $_[1] 	}

sub raw_snapshot_filename	{ shift->{raw_snapshot_filename}   	}
sub set_raw_snapshot_filename	{ shift->{raw_snapshot_filename} = $_[1]}

sub get_frame_grab_options {
	my $self = shift;
	my %par = @_;
	my ($frame) = @par{'frame'};
	
	my $vob_nav_file = $self->vob_nav_file;

	# older transcode versions only support frame grabbing
	# with parameter -c (which decodes all precedent frames,
	# which is very slow.
	if ( $TC::VERSION < 600 or not -f $vob_nav_file ) {
		return {
			c => $frame."-".($frame+1),
		};
	}
	
	# newer versions support direct block navigation
	# by analyzing the tcedmux -W output.
	
	my $fh = FileHandle->new;
	open ($fh, $vob_nav_file) or
		croak "Can't read VOB navigation file '$vob_nav_file'";

	my ($frames, $block_offset, $frame_offset);
	
	while (<$fh>) {
		if ( $frames == $frame ) {
			s/^\s+//;
			($block_offset, $frame_offset) =
				(split (/\s+/, $_))[4,5];
			last;
		}
		++$frames;
	}
	
	close $fh;
	
	return {
		L => $block_offset,
		c => $frame_offset."-".
		     ($frame_offset+1)
	};
}

sub get_take_snapshot_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($frame) = @par{'frame'};

	my $nr      = $self->nr;
	my $tmp_dir = "/tmp/dvdrip$$.ppm";
	
	my $command =
	       "mkdir -m 0775 $tmp_dir; ".
	       "cd $tmp_dir; ".
	       "transcode".
	       " -z -k -i ".$self->vob_dir.
	       " -o snapshot".
	       " -x vob -y ppm ";

#	$command .= "-V " if $self->tc_use_yuv_internal;

	my $options = $self->get_frame_grab_options ( frame => $frame );
	
	my ($opt, $val);
	while ( ($opt, $val) = each %{$options} ) {
		$command .= "-$opt $val ";
	}

	return $command;
}

sub take_snapshot {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($frame, $filename) = @par{'frame','filename'};
	
	$self->system (
		command => $self->get_take_snapshot_command (
			frame => $frame
		),
	);
	
	$self->convert_snapshot (
		filename => $filename,
	);
	
	1;
}

sub get_convert_snapshot_command {
	my $self = shift;
	my %par = @_;
	my ($filename) = @par{'filename'};

	my $tmp_dir = "/tmp/dvdrip$$.ppm";
	my $dirname = dirname ($filename);

	my $raw_filename = $self->raw_snapshot_filename;

	return	"mkdir -m 0775 -p $dirname; ".
		"convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot00000.ppm $filename;".
		"convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot00000.ppm gray:$raw_filename;".
		" rm -r $tmp_dir";

}

sub convert_snapshot {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($filename) = @par{'filename'};

	unlink $filename;
	unlink $self->raw_snapshot_filename;

	my $command = $self->get_convert_snapshot_command (
		filename => $filename
	);
	
	$self->system (
		command => $command
	);

	if ( not -f $filename or not -f $self->raw_snapshot_filename ) {
		croak "msg: Can't grab preview frame!\nPress Cancel and try a smaller frame number."
	}

	$self->calc_snapshot_bounding_box;

	1;
}

sub take_snapshot_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($frame, $filename, $callback) =
	@par{'frame','filename','callback'};

	$self->popen (
		command => $self->get_take_snapshot_command (
			frame => $frame
		),
		callback => $callback,
	);
	
	$self->convert_snapshot (
		filename => $filename,
	);
	
	1;
}

sub take_snapshot_async_start {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($frame, $filename,) =
	@par{'frame','filename'};
	
	$self->set_snapshot_filename ($filename);
	$filename =~ s/\.[^.]+$//;
	$self->set_raw_snapshot_filename ($filename.".raw");

	return $self->popen (
		command => $self->get_take_snapshot_command (
			frame => $frame
		),
	);
}

sub take_snapshot_async_stop {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($fh, $output) = @par{'fh','output'};

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_take_snapshot_command (
				frame => $self->preview_frame_nr
			).
			$output;

	close $fh;
	croak ($message) if $?;

	$self->convert_snapshot (
		filename => $self->snapshot_filename,
	);

	$self->set_snapshot_filename(undef);

	1;
}

sub calc_snapshot_bounding_box {
	my $self = shift;

	my $filename = $self->raw_snapshot_filename;

        open (IN, $filename)
                or die "can't read '$filename'";
        my $blob = "";
        while (<IN>) {
                $blob .= $_;
        }
        close IN;

        my ($min_x, $min_y, $max_x, $max_y, $x, $y);
	my $width  = $min_x = $self->width;
	my $height = $min_y = $self->height;
	my $thres  = 12;

	# search min_y
        for ($x = 0; $x < $width; ++$x) {
		for ($y = 0; $y < $height; ++$y) {
                        if ( unpack("C", substr($blob, $y*$width+$x, 1)) > $thres ) {
                                $min_y = $y if $y < $min_y;
				last;
                        }
                }
        }

	# search max_y
        for ($x = 0; $x < $width; ++$x) {
		for ($y = $height-1; $y >= 0; --$y) {
                        if ( unpack("C", substr($blob, $y*$width+$x, 1)) > $thres ) {
                                $max_y = $y if $y > $max_y;
				last;
                        }
                }
        }

	# search min_x
	for ($y = 0; $y < $height; ++$y) {
	        for ($x = 0; $x < $width; ++$x) {
# print "x=$x y=$y min_x=$min_x c=".unpack("C", substr($blob, $y*$width+$x, 1)),"\n";
                        if ( unpack("C", substr($blob, $y*$width+$x, 1)) > $thres ) {
                                $min_x = $x if $x < $min_x;
				last;
                        }
                }
        }

	# search max_y
	for ($y = 0; $y < $height; ++$y) {
	        for ($x = $width-1; $x >= 0; --$x) {
                        if ( unpack("C", substr($blob, $y*$width+$x, 1)) > $thres ) {
                                $max_x = $x if $x > $max_x;
				last;
                        }
                }
        }

	# height clipping must not be odd
	--$min_y if $min_y % 2;
	++$max_y if $max_y % 2;

	$self->set_bbox_min_x ($min_x);
	$self->set_bbox_min_y ($min_y);
	$self->set_bbox_max_x ($max_x);
	$self->set_bbox_max_y ($max_y);

	1;
}

#---------------------------------------------------------------------
# Methods for making clip and zoom images
#---------------------------------------------------------------------

sub make_preview_clip1 {
	my $self = shift; $self->trace_in;
	
	return $self->make_preview_clip (
		type => "clip1",
	);
}

sub make_preview_clip2 {
	my $self = shift; $self->trace_in;
	
	return $self->make_preview_clip (
		type => "clip2",
	);
}

sub make_preview_clip {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	my $source_file;
	if ( $type eq 'clip1' ) {
		$source_file = $self->preview_filename( type => 'orig' );
	} else {
		$source_file = $self->preview_filename( type => 'zoom' );
	}

	return 1 if not -f $source_file;

	my $target_file = $self->preview_filename( type => $type );
	
	my $catch = $self->system (
		command => "identify -ping $source_file"
	);
	my ($width, $height);
	($width, $height) = ( $catch =~ /(\d+)x(\d+)/ );
	
	my ($top, $bottom, $left, $right);
	if ( $type eq 'clip1' ) {
		$top    = $self->tc_clip1_top;
		$bottom = $self->tc_clip1_bottom;
		$left   = $self->tc_clip1_left;
		$right  = $self->tc_clip1_right;
	} else {
		$top    = $self->tc_clip2_top;
		$bottom = $self->tc_clip2_bottom;
		$left   = $self->tc_clip2_left;
		$right  = $self->tc_clip2_right;
	}
	
	my $new_width  = $width - $left - $right;
	my $new_height = $height - $top - $bottom;

	$self->system (
		command => "convert $source_file -crop ".
			   "${new_width}x${new_height}+$left+$top ".
			   $target_file
	);

	1;
}

sub make_preview_zoom {
	my $self = shift; $self->trace_in;
	my %par = @_;

	my $source_file = $self->preview_filename( type => 'clip1' );
	my $target_file = $self->preview_filename( type => 'zoom' );

	my $new_width  = $self->tc_zoom_width;
	my $new_height = $self->tc_zoom_height;

	if ( not $new_width or not $new_height ) {
		copy ($source_file, $target_file);
		return 1;
	}
	
	my $catch = $self->system (
		command => "identify -ping $source_file"
	);
	my ($width, $height);
	($width, $height) = ( $catch =~ /(\d+)x(\d+)/ );
	
	$self->system (
		command => "convert $source_file -geometry ".
			   "'${new_width}!x${new_height}!' ".
			   $target_file
	);

	1;
}

sub remove_vob_files {
	my $self = shift;
	
	my $vob_dir = $self->vob_dir;
	
	unlink (<$vob_dir/*>);
	
	1;
}

sub get_remove_vobs_command {
	my $self = shift;

	my $vob_dir = $self->vob_dir;

	my $command = "rm $vob_dir/* && echo DVDRIP_SUCCESS";
	
	return $command;
}

1;
