# $Id: Title.pm,v 1.93 2002/09/22 14:38:56 joern Exp $

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
use Video::DVDRip::Audio;
use Video::DVDRip::ProbeAudio;

use Carp;
use strict;

use FileHandle;
use File::Path;
use File::Basename;
use File::Copy;

# Back reference to the project of this title

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1] }

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
sub set_frames			{ shift->{frames}		= $_[1]	}
sub set_size			{ shift->{size}			= $_[1] }
sub set_audio_channel		{ shift->{audio_channel}	= $_[1] }
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

sub tc_audio_tracks		{ shift->{tc_audio_tracks}		}
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
sub tc_video_bitrate		{ shift->{tc_video_bitrate}      	}
sub tc_video_framerate		{ shift->{tc_video_framerate}      	}
sub tc_fast_bisection		{ shift->{tc_fast_bisection}      	}
sub tc_psu_core			{ shift->{tc_psu_core}      		}

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
sub tc_execute_afterwards	{ shift->{tc_execute_afterwards}	}
sub tc_exit_afterwards		{ shift->{tc_exit_afterwards}		}

sub set_tc_audio_tracks		{ shift->{tc_audio_tracks}	= $_[1]	}
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
sub set_tc_video_bitrate	{ shift->{tc_video_bitrate}  	= $_[1]	}
sub set_tc_video_framerate	{ shift->{tc_video_framerate} 	= $_[1]	}
sub set_tc_fast_bisection	{ shift->{tc_fast_bisection} 	= $_[1]	}
sub set_tc_psu_core		{ shift->{tc_psu_core} 		= $_[1]	}

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
sub set_tc_execute_afterwards	{ shift->{tc_execute_afterwards}= $_[1]	}
sub set_tc_exit_afterwards	{ shift->{tc_exit_afterwards}	= $_[1]	}

#------------------------------------------------------------------------
# The following methods are for audio options and access the appropriate
# attributes of the actually selected audio channel.
#------------------------------------------------------------------------

sub tc_volume_rescale {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_volume_rescale;
}

sub volume_rescale {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->audio_tracks
	     ->[$self->audio_channel]
	     ->volume_rescale;
}

sub tc_mp3_quality {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_mp3_quality;
}

sub tc_ac3_passthrough {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_ac3_passthrough;
}

sub tc_audio_codec {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_audio_codec;
}

sub tc_audio_bitrate {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_bitrate;
}

sub tc_audio_filter {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_audio_filter;
}

sub tc_option_n {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_option_n;
}

sub tc_target_track {
	my $self = shift;
	return -1 if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->tc_target_track;
}

sub set_tc_volume_rescale {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_volume_rescale ($_[0]);
}

sub set_tc_mp3_quality {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_mp3_quality ($_[0]);
}

sub set_tc_ac3_passthrough {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_ac3_passthrough ($_[0]);
}

sub set_tc_audio_codec {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_audio_codec ($_[0]);
}

sub set_tc_audio_bitrate {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_bitrate ($_[0]);
}

sub set_tc_audio_filter {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_audio_filter ($_[0]);
}

sub set_tc_option_n {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_option_n ($_[0]);
}

sub set_tc_target_track {
	my $self = shift;
	return if $self->audio_channel == -1;
	$self->tc_audio_tracks
	     ->[$self->audio_channel]
	     ->set_tc_target_track ($_[0]);
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

sub get_vob_size {
	my $self = shift;
	
	my $vob_dir = $self->vob_dir;
	
	my $vob_size = 0;
	$vob_size += -s for <$vob_dir/*>;
	$vob_size = int ($vob_size/1024/1024);
	
	return $vob_size;
}

sub transcode_data_source {
	my $self = shift; $self->trace_in;
	
	my $project = $self->project;
	my $mode    = $project->rip_mode;

	my $source;

	if ( $mode eq 'rip' ) {
		$source = $self->vob_dir;

	} elsif ( $mode eq 'dvd' ) {
		$source = $project->dvd_device;

	} elsif ( $mode eq 'dvd_image' ) {
		$source = $project->dvd_image_dir;

	} elsif ( $mode eq 'vob_title' ) {
		$source = $project->vob_title_dir;
	}

	return $source;
}

sub data_source_options {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($audio_channel) = @par{'audio_channel'};
	
	$audio_channel = $self->audio_channel
		if not defined $audio_channel;
	
	my $mode   = $self->project->rip_mode;
	my $source = $self->transcode_data_source;

	my ($input_filter, $need_title);

	if ( $mode eq 'rip' ) {
		$input_filter = "vob";
		$need_title = 0;

	} elsif ( $mode eq 'dvd' ) {
		$input_filter = "dvd";
		$need_title = 1;

	} elsif ( $mode eq 'dvd_image' ) {
		$input_filter = "dvd";
		$need_title = 1;

	} elsif ( $mode eq 'vob_title' ) {
		$input_filter = "vob";
		$need_title = 0;
	}

	$input_filter .= ",null" if $audio_channel == -1;

	my %options = (
		i => $source,
		x => $input_filter
	);
	
	if ( $need_title ) {
		my $chapter = $self->actual_chapter || -1;
		$options{T} = $self->nr.",$chapter,".$self->tc_viewing_angle;
	}
	
	return \%options;
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

sub target_avi_audio_file {
	my $self = shift;
	my %par = @_;
	my ($nr) = @par{'nr'};
	my $audio_file = $self->target_avi_file;
	$audio_file =~ s/\.[^.]+$//;
	$audio_file = sprintf ("%s-%02d.audio", $audio_file, $nr);
	return $audio_file;
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

sub has_vob_nav_file {
	my $self = shift; $self->trace_in;

	my $old_chapter = $self->actual_chapter;

	$self->set_actual_chapter ( $self->get_first_chapter )
		if $self->tc_use_chapter_mode;

	my $vob_nav_file = $self->vob_nav_file;

	$self->set_actual_chapter ( $old_chapter )
		if $self->tc_use_chapter_mode;

	return -f $vob_nav_file;
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

sub get_last_chapter {
	my $self = shift;
	
	my $chapter_mode = $self->tc_use_chapter_mode;
	return if not $chapter_mode;
	
	my $chapters = $self->get_chapters;
	return $chapters->[@{$chapters}-1];
}

sub calc_program_stream_units {
	my $self = shift;

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

sub get_effective_ratio {
	my $self = shift;
	my %par = @_;
	my ($type) = @par{'type'};	# clip1, zoom, clip2
	
	my $width        = $self->width;
	my $height       = $self->height;
	my $clip1_ratio  = $width / $height;

	my $from_width   = $width  - $self->tc_clip1_left
				   - $self->tc_clip1_right;
	my $from_height  = $height - $self->tc_clip1_top
				   - $self->tc_clip1_bottom;

	return ($from_width, $from_height, $clip1_ratio) if $type eq 'clip1';

	my $zoom_width   = $self->tc_zoom_width  || $width;
	my $zoom_height  = $self->tc_zoom_height || $height;
	my $zoom_ratio   = ($zoom_width/$zoom_height) * ($width/$height) /
			   ($from_width/$from_height);

	return ($zoom_width, $zoom_height, $zoom_ratio) if $type eq 'zoom';

	my $clip2_width  = $zoom_width  - $self->tc_clip2_left
					- $self->tc_clip2_right;
	my $clip2_height = $zoom_height - $self->tc_clip2_top
					- $self->tc_clip2_bottom;

	return ($clip2_width, $clip2_height, $zoom_ratio);
}

sub auto_adjust_clip_zoom {
	my $self = shift;
	my %par = @_;
	my  ($frame_size, $fast_resize) =
	@par{'frame_size','fast_resize'};

	croak "invalid parameter for frame_size ('$frame_size')"
		if not $frame_size =~ /^(big|medium|small)$/;

	my %width_presets;
	if ( $fast_resize ) {
		%width_presets = (
			small  => 496,
			medium => 640,
			big    => 720,
		);
	} else {
		%width_presets = (
			small  => 496,
			medium => 640,
			big    => 768,
		);
	}

	$self->set_tc_fast_resize ( $fast_resize );

	my $results = $self->calculator;

	my $target_width = $width_presets{$frame_size};

	my %result_by_ar_err;
	foreach my $result ( @{$results} ) {
		next if abs($target_width-$result->{clip2_width}) > 16;
		$result_by_ar_err{abs($result->{ar_err})}
			       ->{abs($target_width-$result->{clip2_width})}
			       		= $result;
	}

	my ($min_err)        = sort { $a <=> $b} keys %result_by_ar_err;
	my ($min_width_diff) = sort { $a <=> $b} keys %{$result_by_ar_err{$min_err}};
	my $result = $result_by_ar_err{$min_err}->{$min_width_diff};

	$self->set_tc_zoom_width   ( $result->{zoom_width}   );
	$self->set_tc_zoom_height  ( $result->{zoom_height}  );
	$self->set_tc_clip1_left   ( $result->{clip1_left}   );
	$self->set_tc_clip1_right  ( $result->{clip1_right}  );
	$self->set_tc_clip1_top    ( $result->{clip1_top}    );
	$self->set_tc_clip1_bottom ( $result->{clip1_bottom} );
	$self->set_tc_clip2_left   ( $result->{clip2_left}   );
	$self->set_tc_clip2_right  ( $result->{clip2_right}  );
	$self->set_tc_clip2_top    ( $result->{clip2_top}    );
	$self->set_tc_clip2_bottom ( $result->{clip2_bottom} );

	1;
}

sub calc_zoom {
	my $self = shift;
	my %par = @_;
	my ($width, $height) = @par{'width','height'};

	my $result = $self->get_zoom_parameters (
		target_width       => ($height ? $self->tc_zoom_width  : undef),
		target_height      => ($width  ? $self->tc_zoom_height : undef),
		fast_resize_align  => ($self->tc_fast_resize ? 8 : 0),
		result_align	   => 16,
		result_align_clip2 => 1,
		auto_clip          => 0,
		use_clip1          => 1,
	);

	$self->set_tc_zoom_width   ( $result->{zoom_width}   );
	$self->set_tc_zoom_height  ( $result->{zoom_height}  );
	$self->set_tc_clip1_left   ( $result->{clip1_left}   );
	$self->set_tc_clip1_right  ( $result->{clip1_right}  );
	$self->set_tc_clip1_top    ( $result->{clip1_top}    );
	$self->set_tc_clip1_bottom ( $result->{clip1_bottom} );
	$self->set_tc_clip2_left   ( $result->{clip2_left}   );
	$self->set_tc_clip2_right  ( $result->{clip2_right}  );
	$self->set_tc_clip2_top    ( $result->{clip2_top}    );
	$self->set_tc_clip2_bottom ( $result->{clip2_bottom} );

	1;
}

sub calculator {
	my $self = shift;
	my %par = @_;
	my  ($fast_resize_align, $result_align, $result_align_clip2) =
	@par{'fast_resize_align','result_align','result_align_clip2'};
	my  ($auto_clip, $use_clip1, $video_bitrate) = 
	@par{'auto_clip','use_clip1','video_bitrate'};

	$fast_resize_align  = $self->tc_fast_resize * 8 if not defined $fast_resize_align;
	$result_align       = 16 if not defined $result_align;
	$result_align_clip2 = 1  if not defined $result_align_clip2;
	$auto_clip          = 1  if not defined $auto_clip;
	$use_clip1	    = 0  if not defined $use_clip1;

	my ($width, $height) = ($self->width, $self->height);

	my @result;
	my $last_result;
	my ($actual_width, $actual_height, $best_result);

	for ( my $i=0;;++$i ) {
		my $result = $self->get_zoom_parameters (
			step               => $i,
			step_size          => 1,
			auto_clip          => $auto_clip,
			use_clip1	   => $use_clip1,
			fast_resize_align  => $fast_resize_align,
			result_align	   => $result_align,
			result_align_clip2 => $result_align_clip2,
			video_bitrate	   => $video_bitrate,
		);

		last if $result->{clip2_width} < 200;
		next if $result->{ar_err} > 1;
		next if $fast_resize_align and
			(($result->{clip1_width}  > $result->{zoom_width}) xor
			 ($result->{clip1_height} > $result->{zoom_height}));

		if ( $i != 0 and ( $actual_width  != $result->{clip2_width} or
			           $actual_height != $result->{clip2_height} ) ) {
			push @result, $best_result;
			$best_result = undef;
		}

		if ( not $best_result or
		     $best_result->{ar_err} > $result->{ar_err} ) {
			$best_result = $result;
		}

		$actual_width  = $result->{clip2_width};
		$actual_height = $result->{clip2_height}; 
	}
	
	push @result, $best_result if $best_result;
	
	return \@result;
}

sub get_zoom_parameters {
	my $self = shift;
	my %par = @_;
	my  ($target_width, $target_height, $fast_resize_align, $result_align) =
	@par{'target_width','target_height','fast_resize_align','result_align'};
	my  ($result_align_clip2, $auto_clip, $step, $step_size, $use_clip1) =
	@par{'result_align_clip2','auto_clip','step','step_size','use_clip1'};
	my  ($video_bitrate) =
	@par{'video_bitrate'};

	my ($clip1_top, $clip1_bottom, $clip1_left, $clip1_right);
	my ($clip_top, $clip_bottom, $clip_left, $clip_right);

	my ($width, $height) = ($self->width, $self->height);
	my $ar = $self->aspect_ratio eq '16:9' ? 16/9 : 4/3;
	my $ar_width_factor = $ar / ($width/$height);
	my $zoom_align = $fast_resize_align ? $fast_resize_align : 2;
	$zoom_align  ||= $result_align if not $result_align_clip2;
	$use_clip1 = 1 if not $auto_clip;
	$video_bitrate ||= $self->tc_video_bitrate;
	
	# clip image
	if ( $auto_clip ) {
		$clip_top    = $self->bbox_min_y;
		$clip_bottom = $height - $self->bbox_max_y;
		$clip_left   = $self->bbox_min_x;
		$clip_right  = $width - $self->bbox_max_x;
	} else {
		$clip_top    = $self->tc_clip1_top;
		$clip_bottom = $self->tc_clip1_bottom;
		$clip_left   = $self->tc_clip1_left;
		$clip_right  = $self->tc_clip1_right;
	}

	if ( $use_clip1 ) {
		$clip1_top    = $clip_top;
		$clip1_bottom = $clip_bottom;
		$clip1_left   = $clip_left;
		$clip1_right  = $clip_right;
	} else {
		$clip1_top    = 0;
		$clip1_bottom = 0;
		$clip1_left   = 0;
		$clip1_right  = 0;
	}

	# align clip1 values when fast resizing is enabled
	if ( $fast_resize_align ) {
		$clip1_left   = int($clip1_left   / $zoom_align) * $zoom_align;
		$clip1_right  = int($clip1_right  / $zoom_align) * $zoom_align;
		$clip1_top    = int($clip1_top    / $zoom_align) * $zoom_align;
		$clip1_bottom = int($clip1_bottom / $zoom_align) * $zoom_align;
	}

	# no odd clip values
	--$clip1_left   if $clip1_left   % 2;
	--$clip1_right  if $clip1_right  % 2;
	--$clip1_top    if $clip1_top    % 2;
	--$clip1_bottom if $clip1_bottom % 2;

	# calculate start width and height
	my $clip_width  = $width  - $clip1_left - $clip1_right;
	my $clip_height = $height - $clip1_top  - $clip1_bottom;

	if ( not $target_height ) {
		$target_width ||=
			int($clip_width * $ar_width_factor -
			    $step * $step_size);
	}

	my ($actual_width, $actual_height);
	my ($zoom_width, $zoom_height);
	my ($clip2_width, $clip2_height);
	my ($clip2_top, $clip2_bottom, $clip2_left, $clip2_right);

	if ( $target_width ) {
		$actual_width  = $target_width;
		$actual_height =
			int($clip_height -
			    ($clip_width  * $ar_width_factor - $target_width) /
			    ($ar * $height / $clip_height));
	} else {
		$actual_height = $target_height;
		$actual_width  =
			int($clip_width  * $ar_width_factor -
			    ($clip_height - $actual_height) *
			    ($ar * $height / $clip_height) );
	}

	my $zoom_width  = $actual_width;
	my $zoom_height = $actual_height;

	if ( $zoom_width % $zoom_align ) {
		$zoom_width = int($zoom_width / $zoom_align + 1) * $zoom_align
			if $zoom_width % $zoom_align >= $zoom_align/2;
		$zoom_width = int($zoom_width / $zoom_align) * $zoom_align
			if $zoom_width % $zoom_align < $zoom_align/2;
	}

	if ( $zoom_height % $zoom_align ) {
		$zoom_height = int($zoom_height / $zoom_align + 1) * $zoom_align
			if $zoom_height % $zoom_align >= $zoom_align/2;
		$zoom_height = int($zoom_height  / $zoom_align) * $zoom_align
			if $zoom_height % $zoom_align < $zoom_align/2;
	}

	my $eff_ar = ($zoom_width/$zoom_height) * ($width/$height) /
		     ($clip_width/$clip_height);
	my $ar_err = abs(100 - $eff_ar / $ar * 100);

	if ( not $use_clip1 ) {
		$clip2_left   = int($clip_left   * $zoom_width/$clip_width   /2)*2;
		$clip2_right  = int($clip_right  * $zoom_width/$clip_width   /2)*2;
		$clip2_top    = int($clip_top    * $zoom_height/$clip_height /2)*2;
		$clip2_bottom = int($clip_bottom * $zoom_height/$clip_height /2)*2;
		$result_align_clip2 = 1;
		$result_align = 16 if not defined $result_align;
	}

	$clip2_width  = $zoom_width  - $clip2_left - $clip2_right;
	$clip2_height = $zoom_height - $clip2_top  - $clip2_bottom;

	if ( $result_align_clip2 ) {
		my $rest;
		if ( $rest = $clip2_width % $result_align ) {
			$clip2_left  += $rest / 2;
			$clip2_right += $rest / 2;
			$clip2_width -= $rest;
			if ( $clip2_left % 2 and $clip2_left > $clip2_right ) {
				--$clip2_left;
				++$clip2_right;
			} elsif ( $clip2_left % 2 ) {
				++$clip2_left;
				--$clip2_right;
			}
		}
		if ( $rest = $clip2_height % $result_align ) {
			$clip2_top    += $rest / 2;
			$clip2_bottom += $rest / 2;
			$clip2_height -= $rest;
			if ( $clip2_top % 2 and $clip2_top > $clip2_bottom ) {
				--$clip2_top;
				++$clip2_bottom;
			} elsif ( $clip2_top % 2 ) {
				++$clip2_top;
				--$clip2_bottom;
			}
		}
	}

	my $phys_ar = $clip2_width/$clip2_height;

	# pixels per second
	my $pps = $self->frame_rate * $clip2_width * $clip2_height;
	
	# bits per pixel
	my $bpp = $video_bitrate * 1000 / $pps;
	
	return {
		zoom_width	=> $zoom_width,
		zoom_height	=> $zoom_height,
		eff_ar		=> $eff_ar,
		ar_err		=> $ar_err,
		clip1_left	=> ($clip1_left||0),
		clip1_right	=> ($clip1_right||0),
		clip1_top	=> ($clip1_top||0),
		clip1_bottom	=> ($clip1_bottom||0),
		clip1_width     => $width-$clip1_left-$clip1_right,
		clip1_height    => $height-$clip1_top-$clip1_bottom,
		clip2_left	=> ($clip2_left||0),
		clip2_right	=> ($clip2_right||0),
		clip2_top	=> ($clip2_top||0),
		clip2_bottom	=> ($clip2_bottom||0),
		clip2_width	=> $clip2_width,
		clip2_height	=> $clip2_height,
		phys_ar		=> $phys_ar,
		bpp		=> $bpp,
		exact_width     => $actual_width,
		exact_height    => $actual_height,
	};
}

#---------------------------------------------------------------------
# Methods for Ripping
#---------------------------------------------------------------------

sub is_ripped {
	my $self = shift;
	
	my $project = $self->project;
	return 1 if $project->rip_mode ne 'rip';

	my $name = $project->name;

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

	my $command = "rm -f $vob_dir/$name-???.vob &&\n".
	           "tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device ".
	           "| dr_splitpipe -f $vob_nav_file 1024 ".
		   "  $vob_dir/$name vob >/dev/null && echo DVDRIP_SUCCESS";

	return $command;
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
# Methods for Volume Scanning
#---------------------------------------------------------------------

sub get_scan_command {
	my $self = shift; $self->trace_in;

	my $nr             = $self->tc_title_nr;
	my $audio_channel  = $self->audio_channel;
	my $name           = $self->project->name;
	my $data_source    = $self->transcode_data_source;
	my $vob_dir    	   = $self->vob_dir;
	my $source_options = $self->data_source_options;
	my $rip_mode       = $self->project->rip_mode;

	$self->create_vob_dir;

	my $command;
	
	if ( $rip_mode eq 'rip' ) {
		my $vob_size = $self->get_vob_size;
		$command = "cat $vob_dir/* | dr_progress -m $vob_size -i 5 | tccat -t vob ";

	} else  {
		$command = "tccat ";
		delete $source_options->{x};
		$command .= " -".$_." ".$source_options->{$_} for keys %{$source_options};
		$command .= "| dr_splitpipe -f /dev/null 0 - - ";
	}

	$command .=
	       "| tcextract -a $audio_channel -x ac3 -t vob ".
	       "| tcdecode -x ac3 ".
	       "| tcscan -x pcm && echo DVDRIP_SUCCESS";

	return $command;
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

	my $command =
		"rm -f $vob_dir/$name-???.vob && ".
		"tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device ".
		"| dr_splitpipe -f $vob_nav_file 1024 $vob_dir/$name vob ";

	if ( $audio_channel != -1 ) {
		$command .= 
		       "| tcextract -a $audio_channel -x ac3 -t vob ".
		       "| tcdecode -x ac3 ".
		       "| tcscan -x pcm && echo DVDRIP_SUCCESS";
	} else {
		$command .= ">/dev/null";
	}

	return $command;
}

sub analyze_scan_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};

	return 1 if $self->audio_channel == -1;

	$output =~ s/^.*?--splitpipe-finished--\n//s;

	my $scan_result = Video::DVDRip::Scan->analyze (
		scan_output => $output,
	);

	$self->audio_tracks
	     ->[$self->audio_channel]
	     ->{scan_result} = $scan_result;

	$self->audio_tracks
	     ->[$self->audio_channel]
	     ->set_volume_rescale ( $scan_result->volume_rescale );

	$self->set_tc_volume_rescale ( $scan_result->volume_rescale );

	1;
}

#---------------------------------------------------------------------
# Methods for Probing DVD
#---------------------------------------------------------------------

sub get_probe_command {
	my $self = shift; $self->trace_in;
	
	my $nr            = $self->tc_title_nr;
	my $data_source   = $self->project->rip_data_source;

	my $command =  "tcprobe -i $data_source -T $nr && echo DVDRIP_SUCCESS";

	return $command;
}

sub analyze_probe_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};

	$self->set_probe_result (
		Video::DVDRip::Probe->analyze (
			probe_output => $output,
			title        => $self,
		)
	);

	1;
}

#---------------------------------------------------------------------
# Methods for probing detailed audio information
#---------------------------------------------------------------------

sub get_probe_audio_command {
	my $self = shift; $self->trace_in;
	
	my $nr      = $self->tc_title_nr;
	my $vob_dir = $self->vob_dir;

	return "tcprobe -i $vob_dir && echo DVDRIP_SUCCESS";
}

sub probe_audio {
	my $self = shift; $self->trace_in;
	
	return 1 if $self->audio_channel == -1;
	
	my $output = $self->system (
		command => $self->get_probe_audio_command
	);
	
	$self->analyze_probe_audio_output (
		output => $output,
	);
	
	1;
}

sub analyze_probe_audio_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};

	$self->probe_result->analyze_audio (
		probe_output => $output,
		title  => $self,
	);

	1;
}

#---------------------------------------------------------------------
# Methods for Transcoding
#---------------------------------------------------------------------

sub suggest_transcode_options {
	my $self = shift; $self->trace_in;

	my $rip_mode = $self->project->rip_mode;

	$self->set_tc_viewing_angle ( 1 );
	$self->set_tc_use_yuv_internal ( 1 );
	$self->set_tc_video_codec ( $self->config('default_video_codec') );
	$self->set_tc_multipass ( 1 );
	$self->set_tc_target_size ( 1400 );
	$self->set_tc_disc_size ( 700 );
	$self->set_tc_disc_cnt ( 2 );
	$self->set_tc_video_framerate (
		$self->video_mode eq 'pal' ? 25 : 23.976
	);
	$self->set_tc_psu_core ( $self->video_mode eq 'ntsc' and $rip_mode eq 'rip' );
	$self->calc_video_bitrate;
	$self->set_preset ( "auto_medium_fast" );

	if ( $rip_mode eq 'rip' ) {
		if ( $self->tc_use_chapter_mode ) {
			my $chapter = $self->get_first_chapter;
			$self->set_preview_frame_nr (
				int($self->chapter_frames->{$chapter} / 2)
			);
		} else {
			$self->set_preview_frame_nr ( int($self->frames / 2) );
		}
	} else {
		$self->set_preview_frame_nr ( 200 );
	}

	1;
}

sub calc_video_bitrate {
	my $self = shift;

	my $video_codec = $self->tc_video_codec;

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

	my $video_bitrate = $self->get_optimal_video_bitrate (
		target_size => $self->tc_target_size
	);
	
	$self->set_tc_video_bitrate ( $video_bitrate );

	return 1;
}

sub get_overall_audio_size_and_bitrate {
	my $self = shift;

	my $frames        = $self->frames;
	my $fps           = $self->frame_rate;

	my $runtime = $frames / $fps;

	my $audio_size;
	my $audio_bitrate;

	foreach my $audio ( @{$self->tc_audio_tracks} ) {
		next if $audio->tc_target_track == -1;
		$audio_size += int($runtime * $audio->tc_bitrate / 1000 / 8);
		$audio_bitrate += $audio->tc_bitrate;
	}

	return ($audio_size, $audio_bitrate);
}

sub get_optimal_video_bitrate {
	my $self = shift;
	my %par = @_;
	my ($target_size) = @par{'target_size'};

	my $frames        = $self->frames;
	my $fps           = $self->frame_rate;

	my $runtime = $frames / $fps;

	my ($audio_size, $audio_bitrate) = $self->get_overall_audio_size_and_bitrate;

	my $video_size = $target_size - $audio_size;

	my $video_bitrate = int($video_size/$runtime/1000*1024*1024*8);
	$video_bitrate = 6000 if $video_bitrate > 6000;
	
	if ( $self->tc_video_codec eq 'SVCD' and
	     $video_bitrate + $audio_bitrate > 2748 ) {
		$video_bitrate = 2748 - $audio_bitrate;
	}
	
	return $video_bitrate;
}

sub get_first_audio_track {
	my $self = shift;
	
	return -1 if $self->audio_channel == -1;

	foreach my $audio ( @{$self->tc_audio_tracks} ) {
		return $audio->tc_nr if $audio->tc_target_track == 0;
	}
	
	return -1;
}

sub get_additional_audio_tracks {
	my $self = shift;
	
	my %avi2vob;
	foreach my $audio ( @{$self->tc_audio_tracks} ) {
		next if $audio->tc_target_track == -1;
		next if $audio->tc_target_track == 0;
		$avi2vob{$audio->tc_target_track} = $audio->tc_nr;
	}
	
	return \%avi2vob;
}

sub get_transcode_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($pass, $split) = @par{'pass','split'};

	my $nr             = $self->nr;
	my $avi_file       = $self->avi_file;
	my $audio_channel  = $self->get_first_audio_track;
	my $source_options = $self->data_source_options (
		audio_channel => $audio_channel
	);

	my ($tc_audio_info, $audio_info);

	if ( $audio_channel != -1 ) {
		$tc_audio_info = $self->tc_audio_tracks->[$audio_channel];
		$audio_info    = $self->audio_tracks->[$audio_channel];
	}

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $mpeg = 0;
	$mpeg = "svcd" if $self->tc_video_codec =~ /^SVCD$/;
	$mpeg = "vcd"  if $self->tc_video_codec =~ /^VCD$/;

	my $command = $nice."transcode";

	$command .= " -a $audio_channel" if $audio_channel != -1;

	$command .= " -".$_." ".$source_options->{$_} for keys %{$source_options};
	
	if ( not $mpeg ) {
		$command .=
			" -w ".int($self->tc_video_bitrate).",250,100";
	} elsif ( $mpeg eq 'svcd' ) {
		$command .=
			" -w ".int($self->tc_video_bitrate)
				if $self->tc_video_bitrate;
	}

	if ( $self->tc_start_frame ne '' or
	     $self->tc_end_frame ne '' ) {
		my $start_frame = $self->tc_start_frame;
		my $end_frame   = $self->tc_end_frame;
		$start_frame ||= 0;
		$end_frame   ||= $self->frames;

		if ( $start_frame != 0 ) {
			my $options = $self->get_frame_grab_options (
				frame => $start_frame
			);
			$options->{c} =~ /(\d+)/;
			my $c1 = $1;
			my $c2 = $c1 + $end_frame - $start_frame;
			$command .= " -c $c1-$c2";
			$command .= " -L $options->{L}"
				if $options->{L} ne '';

		} else {
			$command .= " -c $start_frame-$end_frame";
		}
	}

	if ( $mpeg ) {
		my $size = int($self->tc_disc_size * 0.99);
		my $mpeg2enc_opts = "";
		$mpeg2enc_opts .= $split ? " -S $size" : "";
		my ($audio_size, $audio_bitrate) =
			$self->get_overall_audio_size_and_bitrate;
		$audio_bitrate = int($audio_bitrate * 1.01);
		$mpeg2enc_opts .= " -B $audio_bitrate";
		$mpeg2enc_opts = ",'$mpeg2enc_opts'" if $mpeg2enc_opts;

		$command .= " -F 5$mpeg2enc_opts" if $mpeg eq 'svcd';
		$command .= " -F 1$mpeg2enc_opts" if $mpeg eq 'vcd';
		if ( $mpeg eq 'svcd' ) {
			if ( $self->aspect_ratio eq '16:9' ) {
				# 16:9
				if ( $self->last_applied_preset =~ /4_3/ ) {
					$command .= " --export_asr 2";
				} else {
					$command .= " --export_asr 3";
				}
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


	if ( $audio_channel != -1 ) {
		$command .= " -d" if $audio_info->type eq 'lpcm';

		if ( $mpeg ) {
			$command .= " -b ".
				$tc_audio_info->tc_bitrate;
		} else {
			$command .= " -b ".
				$tc_audio_info->tc_bitrate.",0,".
				$tc_audio_info->tc_mp3_quality;
		}

		if ( $tc_audio_info->tc_ac3_passthrough ) {
			$command .=
				" -A -N ".$tc_audio_info->tc_option_n;
		} else {
			$command .= " -s ".$tc_audio_info->tc_volume_rescale
				if $tc_audio_info->tc_volume_rescale != 0 and 
				   $audio_info->type ne 'lpcm';
			$command .= " --a52_drc_off"
				if $tc_audio_info->tc_audio_filter ne 'a52drc';
			$command .= " -J normalize"
				if $tc_audio_info->tc_audio_filter eq 'normalize';
		}
	}

	$command .= " -V "
		if $self->tc_use_yuv_internal;
	$command .= " -C ".$self->tc_anti_alias
		if $self->tc_anti_alias;
	
	if ( $self->tc_deinterlace eq '32detect' ) {
		$command .= " -J 32detect=force_mode=3";

	} elsif ( $self->tc_deinterlace ) {
		$command .= " -I ".$self->tc_deinterlace;
	}

	if ( $self->tc_video_framerate ) {
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

		my $multiple_of = 8;

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
		$command = "mkdir -m 0775 -p '$dir' && cd $dir && $command";
		$command .= " -R $pass";

		if ( $pass == 1 ) {
			$command =~ s/(-x\s+[^\s]+)/$1,null/;
			$command .= " -y ".$self->tc_video_codec.",null";
			$avi_file = "/dev/null";
		}
	}
	
	if ( not $self->tc_multipass or $pass == 2 ) {
		if ( $mpeg ) {
			$command .= " -y mpeg2enc,mp2enc -E 44100";
		} else {
			$command .= " -y ".$self->tc_video_codec;
		}
	}

	if ( $self->tc_psu_core ) {
		$command .=
			" --psu_mode --nav_seek ".$self->vob_nav_file.
			" --no_split ";
	}
	
	$command .= " -o $avi_file";

	$command .= " --print_status 20" if $TC::VERSION >= 610;

	$self->create_avi_dir;

	$command = $self->combine_command_options (
		cmd      => "transcode",
		cmd_line => $command,
		options  => $self->tc_options,
	) if $self->tc_options =~ /\S/;

	$command = "$command && echo DVDRIP_SUCCESS ";

	return $command;
}

sub get_transcode_audio_command {
	my $self = shift;
	my %par = @_;
	my ($vob_nr, $target_nr) = @par{'vob_nr','target_nr'};

	my $source_options = $self->data_source_options (
		audio_channel => $vob_nr
	);

	$source_options->{x} = "null,$source_options->{x}";

	my $tc_audio_info = $self->tc_audio_tracks->[$vob_nr];
	my $audio_info    = $self->audio_tracks->[$vob_nr];

	my $audio_file = $self->target_avi_audio_file ( nr => $target_nr );
	my $dir = dirname ($audio_file);
	
	my $command =
		"mkdir -p $dir && transcode ".
		" -i $source_options->{i}".
		" -x $source_options->{x}".
		" -g 0x0 -y raw -u 50".
		" -a $vob_nr".
		" -o ".$audio_file;

	if ( $self->tc_video_framerate ) {
		my $fr = $self->tc_video_framerate;
		$fr = "24,1" if $fr == 23.976;
		$fr = "30,4" if $fr == 29.97;
		$command .= " -f $fr";
	}

	if ( $tc_audio_info->tc_ac3_passthrough ) {
		$command .= " -A -N ".
			$tc_audio_info->tc_option_n;
	} else {
		$command .= 
			" -b ".$tc_audio_info->tc_bitrate.",0,".
			       $tc_audio_info->tc_mp3_quality;
		$command .= " -s ".$tc_audio_info->tc_volume_rescale
			if $tc_audio_info->tc_volume_rescale != 0;
		
		$command .= " --a52_drc_off "
			if $tc_audio_info->tc_audio_filter ne 'a52drc';
		$command .= " -J normalize"
			if $tc_audio_info->tc_audio_filter eq 'normalize';
	}

	if ( $self->tc_start_frame ne '' or
	     $self->tc_end_frame ne '' ) {
		my $start_frame = $self->tc_start_frame;
		my $end_frame   = $self->tc_end_frame;
		$start_frame ||= 0;
		$end_frame   ||= $self->frames;

		if ( $start_frame != 0 ) {
			my $options = $self->get_frame_grab_options (
				frame => $start_frame
			);
			$options->{c} =~ /(\d+)/;
			my $c1 = $1;
			my $c2 = $c1 + $end_frame - $start_frame;
			$command .= " -c $c1-$c2";
			$command .= " -L $options->{L}"
				if $options->{L} ne '';

		} else {
			$command .= " -c $start_frame-$end_frame";
		}
	}

	$command .= " --print_status 20" if $TC::VERSION >= 601;

	$command .= " && echo DVDRIP_SUCCESS";

	return $command;
}

sub get_merge_audio_command {
	my $self = shift;
	my %par = @_;
	my ($vob_nr, $target_nr) = @par{'vob_nr','target_nr'};

	my $avi_file      = $self->target_avi_file;
	my $audio_file    = $self->target_avi_audio_file ( nr => $target_nr );

	my $command =
		"avimerge".
		" -i $avi_file".
		" -p $audio_file".
		" -a $target_nr".
		" -o $avi_file.merged &&".
		" mv $avi_file.merged $avi_file &&".
		" rm $audio_file &&".
		" echo DVDRIP_SUCCESS";

	return $command;
}

sub get_fast_resize_options {
	my $self = shift;

	my $multiple_of = 8;

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

#---------------------------------------------------------------------
# Methods for MPEG multiplexing
#---------------------------------------------------------------------

sub get_mplex_command {
	my $self = shift; $self->trace_in;

	my $video_codec = $self->tc_video_codec;

	my $avi_file = $self->target_avi_file;
	my $size     = $self->tc_disc_size;

	my $mplex_f  = $video_codec eq 'SVCD' ? 4 : 1;
	my $mplex_v  = $video_codec eq 'SVCD' ? "-V" : "";
	my $vext     = $video_codec eq 'SVCD' ? 'm2v' : 'm1v';

	my $target_file  = "$avi_file-%d.mpg";

	my $command =
		"mplex -f $mplex_f $mplex_v ".
		"-o $target_file $avi_file.$vext $avi_file.mpa && echo DVDRIP_SUCCESS";
	
	return $command;
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

	my $split_mask = sprintf (
		"%s-%03d",
		$self->project->name,
		$self->nr
	);

	my $command =
		"cd $avi_dir && ".
		"avisplit -s $size -i $avi_file -o $split_mask && ".
		"echo DVDRIP_SUCCESS";
	
	return $command;
}

#---------------------------------------------------------------------
# Methods for taking Snapshots
#---------------------------------------------------------------------

sub snapshot_filename {
	my $self = shift;

	return $self->preview_filename( type => 'orig' );
}

sub raw_snapshot_filename {
	my $self = shift;
	
	my $raw_filename = $self->snapshot_filename;
	$raw_filename =~ s/\.jpg$/.raw/;
	
	return $raw_filename;
}

sub get_frame_grab_options {
	my $self = shift;
	my %par = @_;
	my ($frame) = @par{'frame'};

	if ( $self->project->rip_mode ne 'rip' or not $self->has_vob_nav_file ) {
		$self->log ("Fast VOB navigation only available for ripped DVD's, ".
			    "falling back to slow method.")
			if $self->project->rip_mode ne 'rip';
		$self->log ("VOB navigation file is missing. Slow navigation method used.")
			if $self->project->rip_mode eq 'rip' and not $self->has_vob_nav_file;
		return {
			c => $frame."-".($frame+1),
		};
	}

	my $old_chapter = $self->actual_chapter;

	$self->set_actual_chapter ( $self->get_first_chapter )
		if $self->tc_use_chapter_mode;

	my $vob_nav_file = $self->vob_nav_file;

	$self->set_actual_chapter ( $old_chapter )
		if $self->tc_use_chapter_mode;

	my $fh = FileHandle->new;
	open ($fh, $vob_nav_file) or
		croak "msg:Can't read VOB navigation file '$vob_nav_file'";

	my ($found, $block_offset, $frame_offset);

	my $frames = 0;

	while (<$fh>) {
		if ( $frames == $frame ) {
			s/^\s+//;
			s/\s+$//;
			croak "msg:VOB navigation file '$vob_nav_file' is ".
			      "corrupted. Please contact the author."
				if !/^\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+$/;
			($block_offset, $frame_offset) =
				(split (/\s+/, $_))[4,5];
			$found = 1;
			last;
		}
		++$frames;
	}
	
	close $fh;
	
	croak "msg:Can't find frame $frame in VOB navigation file ".
	      "'$vob_nav_file' (which has only $frames frames). ".
	      "Please contact the author."
		if not $found;
	
	return {
		L => $block_offset,
		c => $frame_offset."-".
		     ($frame_offset+1)
	};
}

sub get_take_snapshot_command {
	my $self = shift; $self->trace_in;

	my $nr           = $self->nr;
	my $frame	 = $self->preview_frame_nr;
	my $tmp_dir      = "/tmp/dvdrip$$.ppm";
	my $filename     = $self->preview_filename( type => 'orig' );
	my $raw_filename = $self->raw_snapshot_filename;
	
	my $source_options = $self->data_source_options;

	$source_options->{x} .= ",null";

	my $command =
	       "mkdir -m 0775 $tmp_dir; ".
	       "cd $tmp_dir; ".
	       "transcode ".
	       " -z -k ".
	       " -o snapshot ".
	       " -y ppm,null ";

	$command .= " -".$_." ".$source_options->{$_} for keys %{$source_options};

	my $grab_options = $self->get_frame_grab_options ( frame => $frame );

	$command .= " -".$_." ".$grab_options->{$_} for keys %{$grab_options};

	$command .= " && ".
		"convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot*.ppm $filename && ".
		"convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot*.ppm gray:$raw_filename &&".
		" rm -r $tmp_dir && ".
		"echo DVDRIP_SUCCESS";

	return $command;
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

sub get_view_dvd_command {
	my $self = shift;
	my %par = @_;
	my ($command_tmpl) = @par{command_tmpl};

	my $nr            = $self->nr;
	my $audio_channel = $self->audio_channel;

	my @opts = ( {
		t => $self->nr,
		a => $self->audio_channel,
		m => $self->tc_viewing_angle,
	} );
		
	if ( $self->tc_use_chapter_mode eq 'select' ) {
		my $chapters = $self->tc_selected_chapters;
		if ( not $chapters or not @{$chapters} ) {
			return "echo 'no chapters selected'";
		}
		push @opts, { c => $_ } foreach @{$chapters};
	} else {
		push @opts, { c => 1 };
	}
	
	my $command = $self->apply_command_template (
		template => $command_tmpl,
		opts     => \@opts,
	);
	
	return $command;
}

sub get_view_avi_command {
	my $self = shift;
	my %par = @_;
	my ($command_tmpl, $file) = @par{'command_tmpl','file'};

	my @filenames;
	push @filenames, $file if $file;

	if ( $self->tc_use_chapter_mode ) {
		my $chapters = $self->get_chapters;
		my $filename;
		foreach my $chapter ( @{$chapters} ) {
			$self->set_actual_chapter ($chapter);
			$filename = $self->avi_file;
			push @filenames, $filename if -f $filename;
		}
		$self->set_actual_chapter(undef);

	} else {
		my $filename = $self->avi_file;
		$filename =~ s/\.avi$//;
		push @filenames, glob ("${filename}*");
	}

	croak "msg:You first have to transcode this title."
		if not @filenames;

	my @opts = ( {} );
	push @opts, { f => $_ } for @filenames;

	my $command = $self->apply_command_template (
		template => $command_tmpl,
		opts     => \@opts,
	);
	
	return $command;
}

sub get_view_stdin_command {
	my $self = shift;
	my %par = @_;
	my ($command_tmpl) = @par{'command_tmpl'};

	my $audio_channel = $self->audio_channel;

	my @opts = ( {
		a => 0,
	} );

	my $command = $self->apply_command_template (
		template => $command_tmpl,
		opts     => \@opts,
	);
	
	my $opts = $self->get_frame_grab_options (
		frame => $self->preview_frame_nr,
	);

	my $source_options = $self->data_source_options;

	$command =
		"tccat -i $source_options->{i}".
		" -T $source_options->{T}".
		" -a $audio_channel -S $opts->{L} | $command";

	return $command;
}

sub get_view_vob_image_command {
	my $self = shift;
	my %par = @_;
	my ($command_tmpl) = @par{'command_tmpl'};

	my $nr            = $self->nr;
	my $audio_channel = $self->audio_channel;
	my $angle         = $self->tc_viewing_angle;

	my $command =
		"tccat -i ".$self->project->dvd_device.
		" -a $audio_channel -L ".
		" -T $nr,1,$angle | $command_tmpl";

	return $command;
}

1;
