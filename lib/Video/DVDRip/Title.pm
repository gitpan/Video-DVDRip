# $Id: Title.pm,v 1.137.2.5 2003/03/03 11:43:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Title;

use base Video::DVDRip::Base;

use Video::DVDRip::Probe;
use Video::DVDRip::PSU;
use Video::DVDRip::Audio;
use Video::DVDRip::Subtitle;
use Video::DVDRip::BitrateCalc;
use Video::DVDRip::FilterSettings;

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

sub width			{ shift->{width}			}
sub height			{ shift->{height}			}
sub aspect_ratio		{ shift->{aspect_ratio}			}
sub video_mode			{ shift->{video_mode}			}
sub letterboxed			{ shift->{letterboxed}			}
sub frames			{ shift->{frames}			}
sub runtime			{ shift->{runtime}			}
sub frame_rate			{ shift->{frame_rate}			}
sub bitrates			{ shift->{bitrates}			}
sub audio_tracks		{ shift->{audio_tracks}			}
sub chapters			{ shift->{chapters}			}
sub viewing_angles		{ shift->{viewing_angles}		}
sub dvd_probe_output		{ shift->{dvd_probe_output}		}
sub vob_probe_output		{ shift->{vob_probe_output}		}

sub set_width			{ shift->{width}		= $_[1]	}
sub set_height			{ shift->{height}		= $_[1]	}
sub set_aspect_ratio		{ shift->{aspect_ratio}		= $_[1]	}
sub set_video_mode		{ shift->{video_mode}		= $_[1]	}
sub set_letterboxed		{ shift->{letterboxed}		= $_[1]	}
sub set_frames			{ shift->{frames}		= $_[1]	}
sub set_runtime			{ shift->{runtime}		= $_[1]	}
sub set_frame_rate		{ shift->{frame_rate}		= $_[1]	}
sub set_bitrates		{ shift->{bitrates}		= $_[1]	}
sub set_audio_tracks		{ shift->{audio_tracks}		= $_[1]	}
sub set_chapters		{ shift->{chapters}		= $_[1]	}
sub set_viewing_angles		{ shift->{viewing_angles}	= $_[1]	}
sub set_dvd_probe_output	{ shift->{dvd_probe_output}	= $_[1]	}
sub set_vob_probe_output	{ shift->{vob_probe_output}	= $_[1]	}

#------------------------------------------------------------------------
# Some calculated attributes
#------------------------------------------------------------------------

sub nr				{ shift->{nr}				}
sub size			{ shift->{size}				}
sub audio_channel		{ shift->{audio_channel}		}
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

sub tc_container		{ shift->{tc_container}			}
sub tc_viewing_angle		{ shift->{tc_viewing_angle}      	}
sub tc_deinterlace		{ shift->{tc_deinterlace} || 0 		}
sub tc_anti_alias		{ shift->{tc_anti_alias}  || 0 		}
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
sub tc_video_codec		{ shift->{tc_video_codec}		}
sub tc_video_af6_codec		{ shift->{tc_video_af6_codec}		}
sub tc_video_bitrate		{ shift->{tc_video_bitrate}      	}
sub tc_video_bitrate_manual	{ shift->{tc_video_bitrate_manual}	}
sub tc_video_bitrate_range	{ shift->{tc_video_bitrate_range}	}
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
# implemented below : sub set_tc_video_codec {}
sub set_tc_video_af6_codec	{ shift->{tc_video_af6_codec}	= $_[1]	}
sub set_tc_video_bitrate	{ shift->{tc_video_bitrate}  	= $_[1]	}
sub set_tc_video_bitrate_manual	{ shift->{tc_video_bitrate_manual}= $_[1]	}
sub set_tc_video_bitrate_range	{ shift->{tc_video_bitrate_range} = $_[1]	}
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

#-- Attributes for CD burning -------------------------------------------

sub burn_cd_type		{ shift->{burn_cd_type} || 'iso'	}
sub burn_label			{ shift->{burn_label}			}
sub burn_abstract		{ shift->{burn_abstract}		}
sub burn_number			{ shift->{burn_number}			}
sub burn_abstract_sticky	{ shift->{burn_abstract_sticky}		}
sub burn_files_selected		{ shift->{burn_files_selected}		}

sub set_burn_cd_type		{ shift->{burn_cd_type}		= $_[1]	}
sub set_burn_label		{ shift->{burn_label}		= $_[1]	}
sub set_burn_abstract		{ shift->{burn_abstract}	= $_[1]	}
sub set_burn_number		{ shift->{burn_number}		= $_[1]	}
sub set_burn_abstract_sticky	{ shift->{burn_abstract_sticky}	= $_[1]	}
sub set_burn_files_selected	{ shift->{burn_files_selected}	= $_[1]	}

#-- Attributes for subtitles --------------------------------------------

sub subtitles			{ shift->{subtitles}			}
sub set_subtitles		{ shift->{subtitles}		= $_[1]	}

sub selected_subtitle_id	{ shift->{selected_subtitle_id}		}
sub set_selected_subtitle_id	{ shift->{selected_subtitle_id}	= $_[1]	}

sub subtitle_test		{ shift->{subtitle_test}		}
sub set_subtitle_test		{ shift->{subtitle_test}	= $_[1]	}

#-- Filter Settings -----------------------------------------------------

sub tc_filter_settings {
	my $self = shift;
	if ( not $self->{tc_filter_settings} ) {
		return $self->{tc_filter_settings} =
			Video::DVDRip::FilterSettings->new;
	}
	return $self->{tc_filter_settings};
}

sub tc_filter_setting_id	{ shift->{tc_filter_setting_id}		}
sub set_tc_filter_setting_id	{ shift->{tc_filter_setting_id}	= $_[1]	}

sub tc_selected_filter_setting	{
	my $self = shift;
	return if not $self->tc_filter_setting_id;
	return $self->tc_filter_settings->get_filter_instance (
		id => $self->tc_filter_setting_id
	);
}

sub tc_preview_start_frame	{ shift->{tc_preview_start_frame}	}
sub tc_preview_end_frame	{ shift->{tc_preview_end_frame}		}
sub tc_preview_buffer_frames	{ shift->{tc_preview_buffer_frames} || 20 }

sub set_tc_preview_start_frame	{ shift->{tc_preview_start_frame}=$_[1]	}
sub set_tc_preview_end_frame	{ shift->{tc_preview_end_frame}	= $_[1]	}
sub set_tc_preview_buffer_frames{ shift->{tc_preview_buffer_frames}=$_[1]}

sub tc_use_yuv_internal {
	my $self = shift;

	# enabled only if all selected filters support YUV
	# and we have no odd clipping / resizing
	
	return 0 if $self->tc_clip1_left % 2 or
		    $self->tc_clip1_right % 2 or
		    $self->tc_clip1_top % 2 or
		    $self->tc_clip1_bottom % 2 or
		    $self->tc_clip2_left % 2 or
		    $self->tc_clip2_right % 2 or
		    $self->tc_clip2_top % 2 or
		    $self->tc_clip2_bottom % 2 or
		    $self->tc_zoom_width % 2 or
		    $self->tc_zoom_height % 2;

	foreach my $filter_instance ( @{$self->tc_filter_settings->filters} ) {
		return 0 if not $filter_instance->get_filter->can_yuv;
	}
	
	return 1;
}

#-- Constructor ---------------------------------------------------------

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
		tc_filter_settings   => Video::DVDRip::FilterSettings->new,
	};
	
	return bless $self, $class;
}

sub set_tc_video_codec {
	my $self = shift;
	my ($value) = @_;
	
	$self->{tc_video_codec} = $value;
	
	$self->set_tc_video_af6_codec ('mpeg4') if $value eq 'ffmpeg';
	$self->set_tc_video_af6_codec ('')      if $value ne 'ffmpeg';
	$self->set_tc_video_bitrate_manual (0)
		if $value eq 'VCD';

	return $value;
}

#-- get actually selected audio (or a dummy object, if no track is selected)

sub audio_track {
	my $self = shift;
	if ( $self->audio_channel == -1 ) {
		# no audio track selected. create a dummy object
		print STDERR "Warning: audio track accessed, but no track selected.\n";
		return Video::DVDRip::Audio->new;
	}
	return $self->audio_tracks->[$self->audio_channel];
}

sub set_tc_container {
	my $self = shift;
	my ($container) = @_;

	return $container if $container eq $self->tc_container;

	$self->log ("Set container format to '$container'");
	$self->{tc_container} = $container;

	return if not defined $self->audio_tracks;
	
	my @messages;
	
	if ( $container eq 'avi' ) {
		# no vorbis and mp2 audio here
		foreach my $audio ( @{$self->audio_tracks} ) {
			next if $audio->tc_target_track == -1;
			if ( $audio->tc_audio_codec eq 'vorbis' ) {
				push @messages,
					"Set codec of audio track #".$audio->tc_nr.
					" to 'mp3', 'vorbis' not supported by AVI";
				$audio->set_tc_audio_codec ('mp3');
			} elsif ( $audio->tc_audio_codec eq 'mp2' ) {
				push @messages,
					"Set codec of audio track #".$audio->tc_nr.
					" to 'mp3', 'mp2' not supported by AVI";
				$audio->set_tc_audio_codec ('mp3');
			}
		}
		
		# no (S)VCD here
		if ( $self->tc_video_codec =~ /^S?VCD$/ ) {
			push @messages,
				"Set video codec to 'xvid', '".
				$self->tc_video_codec.
				"' not supported by AVI";
			$self->set_tc_video_codec ("xvid");
		}

	} elsif ( $container eq 'vcd' ) {
		# only mp2 audio here
		foreach my $audio ( @{$self->audio_tracks} ) {
			next if $audio->tc_target_track == -1;
			if ( $audio->tc_audio_codec ne 'mp2' ) {
				push @messages,
					"Set codec of audio track #".$audio->tc_nr.
					" to 'mp2', '".
					$audio->tc_audio_codec.
					"' not supported by (S)VCD";
				$audio->set_tc_audio_codec ('mp2');
			}
		}

		# only (S)VCD here
		if ( $self->tc_video_codec !~ /S?VCD/ ) {
			push @messages,
				"Set video codec to 'SVCD', '".
				$self->tc_video_codec.
				"' not supported by AVI";
			$self->set_tc_video_codec ("SVCD");
		}
		
	} elsif ( $container eq 'ogg' ) {
		# no mp2 and pcm audio here
		foreach my $audio ( @{$self->audio_tracks} ) {
			next if $audio->tc_target_track == -1;
			if ( $audio->tc_audio_codec eq 'mp2' or
			     $audio->tc_audio_codec eq 'pcm' ) {
				push @messages,
					"Set codec of audio track #".$audio->tc_nr.
					" to 'vorbis', '".
					$audio->tc_audio_codec.
					"' not supported by OGG";
				$audio->set_tc_audio_codec ('vorbis');
			}
		}

		# no (S)VCD here
		if ( $self->tc_video_codec =~ /S?VCD/ ) {
			$self->set_tc_video_codec ("xvid");
			push @messages,
				"Set video codec to 'xvid', (S)VCD not supported by OGG";
		}
	}
	
	foreach my $msg ( @messages ) {
		$self->log ($msg);
	}

	return $container;
}

sub is_ogg {
	my $self = shift;
	
	return $self->tc_container eq 'ogg';
}

sub has_vbr_audio {
	my $self = shift;
	
	return 0 if $self->tc_video_bitrate_manual;
	
	foreach my $audio ( @{$self->audio_tracks} ) {
		next if $audio->tc_target_track == -1;
		return 1 if $audio->tc_audio_codec eq 'vorbis';
	}
	
	return 0;
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
	
	return 1 if $self->project->rip_mode ne 'rip';
	
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

sub avi_dir {
	my $self = shift; $self->trace_in;
	
	return sprintf ("%s/%03d",
		$self->project->avi_dir,
		$self->nr,
	);
}

sub get_target_ext {
	my $self = shift; $self->trace_in;

	my $video_codec = $self->tc_video_codec;
	my $ext = ($video_codec =~ /^S?VCD$/) ? "" : ".avi";

	$ext = ".".$self->config('ogg_file_ext') if $self->is_ogg;

	return $ext;
}

sub avi_file {
	my $self = shift; $self->trace_in;

	my $ext = $self->get_target_ext;

	my $target_dir = $self->subtitle_test ? 
		$self->get_subtitle_preview_dir :
		$self->avi_dir;

	if ( $self->tc_use_chapter_mode ) {
		return 	sprintf("%s/%s-%03d-C%03d$ext", 
			$target_dir,
			$self->project->name,
			$self->nr,
			$self->actual_chapter
		);
	} else {
		return 	sprintf("%s/%s-%03d$ext",
			$target_dir,
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
	my ($vob_nr, $avi_nr) = @par{'vob_nr','avi_nr'};

	my $ext = $self->is_ogg ? ".".$self->config('ogg_file_ext') : '.avi';
	$ext = "" if $self->tc_container eq 'vcd';

	my $audio_file = $self->target_avi_file;
	$audio_file =~ s/\.[^.]+$//;
	$audio_file = sprintf ("%s-%02d$ext", $audio_file, $avi_nr);

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

sub preview_scratch_filename {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	return 	sprintf("%s/%s-%03d-preview-scratch-%s.jpg",
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

sub audio_wav_file {
	my $self = shift; $self->trace_in;

	my $chap;
	if ( $self->actual_chapter ) {
		$chap = sprintf ("-C%02d", $self->actual_chapter);
	}

	return 	sprintf("%s/%s-%03d-%02d$chap.wav",
		$self->avi_dir,
		$self->project->name,
		$self->nr,
		$self->audio_track->tc_nr,
	);
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

	my $zoom_width   = $self->tc_zoom_width  || $from_width;
	my $zoom_height  = $self->tc_zoom_height || $from_height;
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
	my $range = 16;
	while ( keys (%result_by_ar_err) == 0 ) {
		foreach my $result ( @{$results} ) {
			next if abs($target_width-$result->{clip2_width}) > $range;
			$result_by_ar_err{abs($result->{ar_err})}
				       ->{abs($target_width-$result->{clip2_width})}
				       		= $result;
		}
		$range += 16;
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

#use Data::Dumper; print Dumper(\%par);

	my ($clip1_top, $clip1_bottom, $clip1_left, $clip1_right);
	my ($clip_top, $clip_bottom, $clip_left, $clip_right);

	my ($width, $height) = ($self->width, $self->height);
	my $ar = $self->aspect_ratio eq '16:9' ? 16/9 : 4/3;
	my $ar_width_factor = $ar / ($width/$height);
	my $zoom_align = $fast_resize_align ? $fast_resize_align : 2;
	$zoom_align  ||= $result_align if not $result_align_clip2;
	$use_clip1 = 1 if not $auto_clip;
	$video_bitrate ||= $self->tc_video_bitrate;

#print "width=$width height=$height\n";
	
	# clip image
	if ( $auto_clip ) {
		$clip_top    = $self->bbox_min_y || 0;
		$clip_bottom = defined $self->bbox_max_y ?
					$height - $self->bbox_max_y : 0;
		$clip_left   = $self->bbox_min_x || 0;
		$clip_right  = defined $self->bbox_max_x ?
					$width - $self->bbox_max_x : 0;
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

#print "clip_width=$clip_width clip_height=$clip_height\n";

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

#print "actual_width=$actual_width actual_height=$actual_height\n";

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

#print "zoom_width=$zoom_width zoom_height=$zoom_height\n";

	my $eff_ar = ($zoom_width/$zoom_height) * ($width/$height) /
		     ($clip_width/$clip_height);
	my $ar_err = abs(100 - $eff_ar / $ar * 100);

#print "clip_left=$clip_left clip_right=$clip_right clip_top=$clip_top clip_bottom=$clip_bottom\n";

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

#print "clip2_width=$clip2_width clip2_height=$clip2_height\n";

	if ( $result_align_clip2 ) {
		$result_align ||= 16; # fail safe -> prevent division by zero
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

	my $command = "rm -f $vob_dir/$name-???.vob && ".
	           "dr_exec tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device ".
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

sub get_tc_scan_command_pipe {
	my $self = shift; $self->trace_in;
	
	my $audio_channel  = $self->audio_channel;
	my $codec          = $self->audio_track->type =~ /pcm/ ? 'pcm' : 'ac3';
	my $tcdecode       = $codec eq 'ac3' ? "| tcdecode -x ac3 " : "";

	my $command .=
	       "dr_exec tcextract -a $audio_channel -x $codec -t vob ".
	       $tcdecode.
	       "| tcscan -x pcm";

	return $command;
}

sub get_scan_command {
	my $self = shift; $self->trace_in;

	my $nr             = $self->tc_title_nr;
	my $name           = $self->project->name;
	my $data_source    = $self->transcode_data_source;
	my $vob_dir    	   = $self->vob_dir;
	my $source_options = $self->data_source_options;
	my $rip_mode       = $self->project->rip_mode;

	$self->create_vob_dir;

	my $command;
	
	if ( $rip_mode eq 'rip' ) {
		my $vob_size = $self->get_vob_size;
		$command = "dr_exec cat $vob_dir/* | dr_progress -m $vob_size -i 5 | tccat -t vob";

	} else  {
		$command = "dr_exec tccat ";
		delete $source_options->{x};
		$command .= " -".$_." ".$source_options->{$_} for keys %{$source_options};
		$command .= "| dr_splitpipe -f /dev/null 0 - -";
	}

	my $scan_command = $self->get_tc_scan_command_pipe;
	$scan_command =~ s/dr_exec\s+//;

	$command .= " | $scan_command";
	$command .= " && echo DVDRIP_SUCCESS";

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
		"dr_exec tccat -t dvd -T $nr,$chapter,$angle -i $dvd_device ".
		"| dr_splitpipe -f $vob_nav_file 1024 $vob_dir/$name vob ";

	if ( $audio_channel != -1 ) {
		my $scan_command = $self->get_tc_scan_command_pipe;
		$scan_command =~ s/dr_exec\s+//;
		$command .= " | $scan_command && echo DVDRIP_SUCCESS";

	} else {
		$command .= ">/dev/null && echo DVDRIP_SUCCESS";
	}

	return $command;
}

sub analyze_scan_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output, $count) = @par{'output','count'};

	return 1 if $self->audio_channel == -1;

	$output =~ s/^.*?--splitpipe-finished--\n//s;

	Video::DVDRip::Probe->analyze_scan (
		scan_output => $output,
		audio       => $self->audio_track,
		count	    => $count,
	);

	1;
}

#---------------------------------------------------------------------
# Methods for Probing DVD
#---------------------------------------------------------------------

sub get_probe_command {
	my $self = shift; $self->trace_in;
	
	my $nr            = $self->tc_title_nr;
	my $data_source   = $self->project->rip_data_source;

	my $command =
		"dr_exec tcprobe -i $data_source -T $nr && ".
		"echo DVDRIP_SUCCESS; ".
		"dr_exec dvdxchap -t $nr $data_source 2>/dev/null";

	return $command;
}

sub analyze_probe_output {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($output) = @par{'output'};

	Video::DVDRip::Probe->analyze (
		probe_output => $output,
		title        => $self,
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

	return "dr_exec tcprobe -i $vob_dir && echo DVDRIP_SUCCESS";
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

	Video::DVDRip::Probe->analyze_audio (
		probe_output => $output,
		title        => $self,
	);

	1;
}

#---------------------------------------------------------------------
# Methods for Transcoding
#---------------------------------------------------------------------

sub suggest_transcode_options {
	my $self = shift; $self->trace_in;

	my $rip_mode = $self->project->rip_mode;

	$self->set_tc_container ( 'avi' );
	$self->set_tc_viewing_angle ( 1 );
	$self->set_tc_video_codec ( $self->config('default_video_codec') );
	$self->set_tc_multipass ( 1 );
	$self->set_tc_target_size ( 1406 );
	$self->set_tc_disc_size ( 703 );
	$self->set_tc_disc_cnt ( 2 );
	$self->set_tc_video_framerate (
		$self->video_mode eq 'pal' ? 25 : 23.976
	);
	
	if ( $self->video_mode eq 'ntsc' and $rip_mode eq 'rip' and
	     @{$self->program_stream_units} > 1 ) {
		$self->set_tc_psu_core (1);
		$self->log ("Enabled PSU core. Movie is NTSC and has more than one PSU.");

	} elsif ( $self->video_mode eq 'ntsc' and $rip_mode eq 'rip' ) {
		$self->log ("Not enabling PSU core, because this movie has only one PSU.");
	}

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
		$self->audio_track->set_tc_bitrate ( 224 );
		$self->audio_track->set_tc_audio_codec ( 'mp2' );
		$self->set_tc_multipass ( 0 );
	}
	
	if ( $video_codec eq 'SVCD' ) {
		$self->audio_track->set_tc_audio_codec ( 'mp2' );
		$self->set_tc_multipass ( 0 );
	}

	return $self->tc_video_bitrate if $self->tc_video_bitrate_manual;

	my $bc = Video::DVDRip::BitrateCalc->new (
		title => $self,
	);

	$bc->calculate_video_bitrate;

	return $self->set_tc_video_bitrate ( $bc->video_bitrate );
}

sub get_first_audio_track {
	my $self = shift;

	return -1 if $self->audio_channel == -1;
	return -1 if not $self->audio_tracks;

	foreach my $audio ( @{$self->audio_tracks} ) {
		return $audio->tc_nr if $audio->tc_target_track == 0;
	}
	
	return -1;
}

sub get_additional_audio_tracks {
	my $self = shift;
	
	my %avi2vob;
	foreach my $audio ( @{$self->audio_tracks} ) {
		next if $audio->tc_target_track == -1;
		next if $audio->tc_target_track == 0;
		$avi2vob{$audio->tc_target_track} = $audio->tc_nr;
	}
	
	return \%avi2vob;
}

sub get_transcode_frame_cnt {
	my $self = shift;
	my %par = @_;
	my ($chapter) = @par{'chapter'};

	my $frames;
	if ( not $chapter ) {
		if ( $self->tc_start_frame ne '' or
		     $self->tc_end_frame ne '' ) {
		     	$frames = $self->tc_end_frame || $self->frames;
			$frames = $frames - $self->tc_start_frame
				     	if $self->has_vob_nav_file;
			$frames ||= $self->frames;
		} else {
			$frames = $self->frames;
		}
	} else {
		$frames = $self->chapter_frames->{$chapter};
	}

	return $frames;
}

sub get_transcode_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($pass, $split, $no_audio, $output_file) =
	@par{'pass','split','no_audio','output_file'};

	my $bc = Video::DVDRip::BitrateCalc->new (
		title => $self,
	);
	$bc->calculate_video_bitrate;

	my $nr             = $self->nr;
	my $avi_file       = $output_file || $self->avi_file;
	my $audio_channel  = $self->get_first_audio_track;

	$audio_channel = -1 if $no_audio;

	my $source_options = $self->data_source_options (
		audio_channel => $audio_channel
	);

	my ($audio_info);

	if ( $audio_channel != -1 ) {
		$audio_info = $self->audio_tracks->[$audio_channel];
	}

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $mpeg = 0;
	$mpeg = "svcd" if $self->tc_video_codec =~ /^SVCD$/;
	$mpeg = "vcd"  if $self->tc_video_codec =~ /^VCD$/;

	my $command = $nice."dr_exec transcode";

	$command .= " -a $audio_channel" if $audio_channel != -1;

	$command .= " -".$_." ".$source_options->{$_} for keys %{$source_options};
	
	if ( not $mpeg ) {
		$command .=
			" -w ".int($self->tc_video_bitrate);
	} elsif ( $mpeg eq 'svcd' and $self->tc_video_bitrate ) {
		$command .=
			" -w ".int($self->tc_video_bitrate);
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
		my $size = $bc->disc_size;
		my $reserve_bitrate = $bc->vcd_reserve_bitrate;
		my $mpeg2enc_opts = "-B $reserve_bitrate ";
		if ( $split ) {
			$mpeg2enc_opts   .= "-S $size ";
		} else {
			$mpeg2enc_opts   .= "-S 10000 ";
		}

		if ( $mpeg eq 'svcd' ) {
			if ( $self->video_mode eq 'pal' ) {
				$mpeg2enc_opts .= " -g 6 -G 15";
			} else {
				$mpeg2enc_opts .= " -g 9 -G 18";
				if ( $self->frame_rate == 23.976 ) {
					$mpeg2enc_opts .= " -I 0 -p";
				}
			}

			$mpeg2enc_opts = ",'$mpeg2enc_opts'" if $mpeg2enc_opts;

			$command .= " -F 5$mpeg2enc_opts";

			if ( $self->aspect_ratio eq '16:9' ) {
				# 16:9
				if ( $self->last_applied_preset =~ /4_3/ ) {
					# 4:3 with black bars
					$command .= " --export_asr 2";
				} else {
					$command .= " --export_asr 3";
				}
			} else {
				# 4:3
				$command .= " --export_asr 2";
			}
		} else {
			$mpeg2enc_opts = ",'$mpeg2enc_opts'" if $mpeg2enc_opts;
			$command .= " -F 1$mpeg2enc_opts --export_asr 2";
		}
	
		
	} else {
		$command .= " -F ".$self->tc_video_af6_codec
			if $self->tc_video_af6_codec ne '';
	}


	if ( $audio_channel != -1 ) {
		$command .= " -d" if $audio_info->type eq 'lpcm';

		if ( $mpeg ) {
			$command .= " -b ".
				$audio_info->tc_bitrate;
		} elsif ( $audio_info->tc_audio_codec =~ /^mp\d/ ) {
			$command .= " -b ".
				$audio_info->tc_bitrate.",0,".
				$audio_info->tc_mp3_quality;
		} elsif ( $audio_info->tc_audio_codec eq 'vorbis' ) {
			if ( $audio_info->tc_vorbis_quality_enable ) {
				$command .= " -b 0,1,".
					$audio_info->tc_vorbis_quality;
			} else {
				$command .= " -b ".
					$audio_info->tc_bitrate;
			}
		}

		if ( $audio_info->tc_audio_codec eq 'ac3' ) {
			$command .=
				" -A -N ".$audio_info->tc_option_n;

		} elsif ( $audio_info->tc_audio_codec eq 'pcm' ) {
			$command .=
				" -N 0x1";

		} else {
			$command .= " -s ".$audio_info->tc_volume_rescale
				if $audio_info->tc_volume_rescale != 0 and 
				   $audio_info->type ne 'lpcm';
			$command .= " --a52_drc_off"
				if $audio_info->tc_audio_filter ne 'a52drc';
			$command .= " -J normalize"
				if $audio_info->tc_audio_filter eq 'normalize';
		}
	}

	$command .= " -V "
		if $self->tc_use_yuv_internal and
		   ( $self->version ("transcode") >= 603 or
		     $self->tc_deinterlace ne 'smart' );

	$command .= " -C ".$self->tc_anti_alias
		if $self->tc_anti_alias;
	
	if ( $self->tc_deinterlace eq '32detect' ) {
		$command .= " -J 32detect=force_mode=3";

	} elsif ( $self->tc_deinterlace eq 'smart' ) {
		$command .= " -J smartdeinter=threshold=10:Blend=1:diffmode=2:highq=1";

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

	my $clip1 = ($self->tc_clip1_top||0).",".
		    ($self->tc_clip1_left||0).",".
		    ($self->tc_clip1_bottom||0).",".
		    ($self->tc_clip1_right||0);

	$command .= " -j $clip1"
		if $clip1 =~ /^-?\d+,-?\d+,-?\d+,-?\d+$/ and $clip1 ne '0,0,0,0';

	my $clip2 = ($self->tc_clip2_top||0).",".
		    ($self->tc_clip2_left||0).",".
		    ($self->tc_clip2_bottom||0).",".
		    ($self->tc_clip2_right||0);

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
			} elsif ( $width_n < 0 or $height_n < 0 ) {
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

		if ( $pass == 1 and not $self->has_vbr_audio or
		     $pass == 2 and     $self->has_vbr_audio ) {
			$command =~ s/(-x\s+[^\s]+)/$1,null/;
			$command =~ s/-x\s+([^,]+),null,null/-x $1,null/;
			$command .= " -y ".$self->tc_video_codec;
			$command .= ",null" if not $self->has_vbr_audio or $pass == 2;
			$avi_file = "/dev/null" if not $self->has_vbr_audio;
		}
	}
	
	if ( not $self->tc_multipass or ( $pass == 2 xor $self->has_vbr_audio ) ) {
		if ( $mpeg ) {
			$command .= " -y mpeg2enc,mp2enc -E 44100";
		} else {
			$command .= " -y ".$self->tc_video_codec;
			if ( $self->tc_container eq 'ogg' and
			     $audio_channel != -1 ) {
			     	$command .= ",ogg"
					if $audio_info->tc_audio_codec eq 'vorbis';
				$command .= " -m ".$self->target_avi_audio_file (
					vob_nr => $audio_channel,
					avi_nr => 0
				);
			}
			if ( $audio_channel == -1 ) {
				$command .= ",null";

			} else {
				if ( $audio_info->tc_samplerate !=
				     $audio_info->sample_rate and
				     $audio_info->tc_samplerate ) {
					$command .= " -E ".$audio_info->tc_samplerate
						if $audio_info->tc_samplerate;
					$command .= " -J resample"
						if $audio_info->tc_audio_codec eq 'vorbis';
				}
			}
		}
	}

	if ( $self->tc_psu_core ) {
		$command .=
			" --psu_mode --nav_seek ".$self->vob_nav_file.
			" --no_split ";
	}
	
	$command .= " -o $avi_file";

	$command .= " --print_status 20";

	# Filters
	my $config_strings =
	$self->tc_filter_settings
	     ->get_filter_config_strings;

	foreach my $config ( @{$config_strings} ) {
		next if not $config->{enabled};
		$command .= " -J $config->{filter}";
		$command .= "=$config->{options}" if $config->{options};
	}

	$self->create_avi_dir;

	$command = $self->combine_command_options (
		cmd      => "transcode",
		cmd_line => $command,
		options  => $self->tc_options,
	) if $self->tc_options =~ /\S/;

	$command .= $self->get_subtitle_transcode_options;

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

	my $audio_info = $self->audio_tracks->[$vob_nr];

	my $audio_file = $self->target_avi_audio_file (
		vob_nr => $vob_nr,
		avi_nr => $target_nr
	);

	my $dir = dirname ($audio_file);

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $command =
		"mkdir -p $dir && ".
		"${nice}dr_exec transcode ".
		" -g 0x0 -u 50".
		" -a $vob_nr".
		" -y raw";

	if ( $self->is_ogg ) {
		if ( $audio_info->tc_audio_codec eq 'vorbis' ) {
			$command .= ",ogg -m $audio_file";
		} else {
			$command .= " -m $audio_file";
		}

	} elsif ( $self->tc_container eq 'vcd' ) {
		$command .= ",mp2enc -o $audio_file";

	} else {
		$command .= " -o ".$audio_file;
	}

	my ($k,$v);
	while ( ($k, $v) = each %{$source_options} ) {
		$command .= " -$k $v";
	}	

	if ( $self->tc_video_framerate ) {
		my $fr = $self->tc_video_framerate;
		$fr = "24,1" if $fr == 23.976;
		$fr = "30,4" if $fr == 29.97;
		$command .= " -f $fr";
	}

	if ( $audio_info->tc_audio_codec eq 'ac3' ) {
		$command .=
			" -A -N ".$audio_info->tc_option_n;

	} elsif ( $audio_info->tc_audio_codec eq 'pcm' ) {
		$command .=
			" -N 0x1";

	} else {

		if ( $audio_info->tc_audio_codec =~ /^mp\d/ ) {
			$command .= " -b ".
				$audio_info->tc_bitrate.",0,".
				$audio_info->tc_mp3_quality;

		} elsif ( $audio_info->tc_audio_codec eq 'vorbis' ) {
			if ( $audio_info->tc_vorbis_quality_enable ) {
				$command .= " -b 0,".
					$audio_info->tc_vorbis_quality;
			} else {
				$command .= " -b ".
					$audio_info->tc_bitrate;
			}
		}

		$command .= " -s ".$audio_info->tc_volume_rescale
			if $audio_info->tc_volume_rescale != 0;
		
		$command .= " --a52_drc_off "
			if $audio_info->tc_audio_filter ne 'a52drc';
		$command .= " -J normalize"
			if $audio_info->tc_audio_filter eq 'normalize';

		if ( $audio_info->tc_samplerate !=
		     $audio_info->sample_rate and
		     $audio_info->tc_samplerate ) {
			$command .= " -E ".$audio_info->tc_samplerate
				if $audio_info->tc_samplerate;
			$command .= " -J resample"
				if $audio_info->tc_audio_codec eq 'vorbis';
		}
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

	if ( $self->tc_psu_core ) {
		$command .=
			" --psu_mode --nav_seek ".$self->vob_nav_file.
			" --no_split ";
	}

	$command .= " --print_status 20";

	$command = $self->combine_command_options (
		cmd      => "transcode",
		cmd_line => $command,
		options  => $self->tc_options,
	) if $self->tc_options =~ /\S/;

	if ( $self->tc_container eq 'vcd' ) {
		$command .= " && rm -f ".$self->target_avi_file;
	}

	$command .= " && echo DVDRIP_SUCCESS";

	return $command;
}

sub get_merge_audio_command {
	my $self = shift;
	my %par = @_;
	my ($vob_nr, $target_nr) = @par{'vob_nr','target_nr'};

	my $avi_file      = $self->target_avi_file;
	my $audio_file;
	$audio_file       = $self->target_avi_audio_file (
		vob_nr => $vob_nr,
		avi_nr => $target_nr
	) if $vob_nr != -1;

	my $command;

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	$command = $nice;

	if ( $self->is_ogg ) {
		$command .=
			"dr_exec ogmmerge -o $avi_file.merged ".
			" $avi_file".
			" $audio_file &&".
			" mv $avi_file.merged $avi_file &&".
			" rm -f $audio_file &&".
			" echo DVDRIP_SUCCESS";
		
	} else {
		die "avimerge without audio isn't possible"
			if not $audio_file;

		$command .=
			"dr_exec avimerge".
			" -i $avi_file".
			" -p $audio_file".
			" -a $target_nr".
			" -o $avi_file.merged &&".
			" mv $avi_file.merged $avi_file &&".
			" rm $audio_file &&".
			" echo DVDRIP_SUCCESS";
	}

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

	$zoom_width  ||= $width;
	$zoom_height ||= $height;

	my $width_n  = ($zoom_width  - $width)  / $multiple_of;
	my $height_n = ($zoom_height - $height) / $multiple_of;

	my ($err_div32, $err_shrink_expand);

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

	my $mplex_f  = $video_codec eq 'SVCD' ? 5 : 1;
	my $mplex_v  = $video_codec eq 'SVCD' ? "-V" : "";
	my $vext     = $video_codec eq 'SVCD' ? 'm2v' : 'm1v';

	my $target_file  = "$avi_file-%d.mpg";

	my $add_audio_tracks;
	my $add_audio_tracks_href = $self->get_additional_audio_tracks;

	if ( keys %{$add_audio_tracks_href} ) {
		my ($avi_nr, $vob_nr);
		foreach $avi_nr ( sort keys %{$add_audio_tracks_href} ) {
			$vob_nr = $add_audio_tracks_href->{$avi_nr};
			$add_audio_tracks .= " ".
			  $self->target_avi_audio_file (
				vob_nr => $vob_nr,
				avi_nr => $avi_nr,
			  ).".mpa";
		}
	}

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $command =
		"${nice}dr_exec mplex -f $mplex_f $mplex_v ".
		"-o $target_file $avi_file.$vext $avi_file.mpa ".
		"$add_audio_tracks && echo DVDRIP_SUCCESS";
	
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
		$self->nr,
	);

	my $command;

	if ( -s "$avi_dir/$avi_file" > 0 and
	     -s "$avi_dir/$avi_file" <= $size * 1024 * 1024 ) {
		$command =
			"echo File is smaller than one disc, no need to split.".
			"&& echo DVDRIP_SUCCESS";
		return $command;
	}

	my $nice;
	$nice = "`which nice` -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	if ( $self->is_ogg ) {
		$split_mask .= $self->config('ogg_file_ext');

		$command .=
			"cd $avi_dir && ".
			"${nice}dr_exec ogmsplit -s $size $avi_file && ".
			"echo DVDRIP_SUCCESS";
	} else {
		$command .=
			"cd $avi_dir && ".
			"${nice}dr_exec avisplit -s $size -i $avi_file -o $split_mask && ".
			"echo DVDRIP_SUCCESS";
	}
	
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
			      "corrupted."
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
	      "'$vob_nav_file' (which has only $frames frames). "
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
	       "dr_exec transcode ".
	       " -z -k ".
	       " -o snapshot ".
	       " -y ppm,null ";

	$command .= " -".$_." ".$source_options->{$_} for keys %{$source_options};

	my $grab_options = $self->get_frame_grab_options ( frame => $frame );

	$command .= " -".$_." ".$grab_options->{$_} for keys %{$grab_options};

	$command .= " && ".
		"dr_exec convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot*.ppm $filename && ".
		"dr_exec convert".
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

	my $command =
		"convert $source_file -crop ".
	        "${new_width}x${new_height}+$left+$top ".
		$target_file;

	$self->system (
		command => "convert $source_file -crop ".
			   "${new_width}x${new_height}+$left+$top ".
			   $target_file
	);

	$self->put_preview_on_scratch (
		source_file => $target_file,
		target_file => $self->preview_scratch_filename ( type => $type ),
		width       => $new_width,
		height      => $new_height,
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

	$self->put_preview_on_scratch (
		source_file => $target_file,
		target_file => $self->preview_scratch_filename ( type => 'zoom' ),
		width       => $new_width,
		height      => $new_height,
	);	

	1;
}

sub put_preview_on_scratch {
	my $self = shift;
	my %par = @_;
	my  ($source_file, $target_file, $width, $height) =
	@par{'source_file','target_file','width','height'};
return 1;

	my $scratch_width  = $Video::DVDRIP::scratch_width;
	my $scratch_height = $Video::DVDRIP::scratch_height;
	
	my $x = int(($scratch_width-$width) / 2);
	my $y = int(($scratch_height-$height) / 2);

	my $white_file = $self->project->snap_dir.
		"/scratch-${scratch_width}x${scratch_height}.png";

	my $command;

	if ( not -f $white_file ) {
		$command .= "convert -size ${scratch_width}x${scratch_height} ".
			    " xc:white $white_file";
	}
	
	$command .=
		" && composite -geometry ${width}x${height}+$x+$y".
		" $source_file $white_file $target_file";
	
	$command =~ s/^ &&//;

print "\n",$command,"\n";

	$self->system (
		command => $command
	);
	
	1;
}

#---------------------------------------------------------------------

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
	if ( $file ) {
		@filenames = ( $file );

	} elsif ( $self->tc_use_chapter_mode ) {
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
		my $ext = $self->get_target_ext;
		$filename =~ s/\.[^.]+$//;
		push @filenames, grep !/dvdrip-info/,
				 glob ("${filename}*".$ext);
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

	my $T;
	$T = "-T $source_options->{T}" if $source_options->{T};

	$command =
		"tccat -i $source_options->{i}".
		" $T".
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
		"dr_exec tccat -i ".$self->project->dvd_device.
		" -a $audio_channel -L ".
		" -T $nr,1,$angle | $command_tmpl";

	return $command;
}

#---------------------------------------------------------------------
# CD burning stuff
#---------------------------------------------------------------------

sub get_burn_files {
	my $self = shift;
	
	my $cd_type = $self->burn_cd_type || 'iso';

	my $ogg_ext = $self->config('ogg_file_ext');

	my $mask =
		$cd_type eq 'iso' ? "*.{avi,$ogg_ext,iso,dvdrip-info,sub,ifo,idx,rar}" :
		$cd_type eq 'vcd' ? "*.{mpg,vcd}" :
				    "*.{mpg,svcd}";

	$mask = $self->avi_dir."/".$mask;

	my @files = glob ($mask);

	my @burn_files;
	my %files_per_group;
	my ($label, $abstract, $base, $group, $index, $is_image, $ext, $chapter);

	foreach my $file ( sort @files ) {
		$base = basename ($file);

		$base =~ /^(.*?)([_-]\d+)([_-](C?)\d+)?\.([^\.]+)$/;
		$index = $3;
		$chapter = $4;
		$group = "$1:$5";
		
		$base =~ /([^\.]+)$/;
		$ext   = $1;

		$index =~ s/C//g;
		$index = $index * -1 if $index < 0;
		++$files_per_group{$group};

		$is_image = $ext =~ /^(iso|vcd|svcd)$/;
		++$index if $cd_type eq 'iso' and not $chapter; # avi counting begins with 0

		$label = $base;
		$label =~ s/(-C?\d+)*\.[^\.]+$//;

		$abstract = $label;
		$abstract =~ s/_/ /g;
		$abstract =~ s/\b(.)/uc($1)/eg;

		$label .= "_$index" if not $is_image;
		
		push @burn_files, {
			name     => $base,
			label    => $label,
			abstract => $abstract,
			size     => (int((-s $file)/1024/1024)||1),
			group    => $group,
			index    => $index,
			path     => $file,
			is_image => $is_image
		};
	}

	foreach my $file ( @burn_files ) {
		$file->{number} =
			"$file->{index} of ".
			$files_per_group{$file->{group}};
	}

	return \@burn_files;
}

sub cd_image_file {
	my $self = shift;

	my $cd_type = $self->burn_cd_type;

	my @labels = map  { $_->{label} }
		     sort { $a->{label} cmp $b->{label} }
		     values %{$self->burn_files_selected};
	
	return $self->avi_dir."/".$labels[0].".$cd_type";
}

sub burning_an_image {
	my $self = shift;

	my $is_image;
	map  { $is_image = 1 if $_->{is_image} }
	  sort { $a->{path} cmp $b->{path} }
 	  values %{$self->burn_files_selected};

	return $is_image;
}

sub get_create_image_command {
	my $self = shift;
	my %par = @_;
	my ($on_the_fly) = @par{'on_the_fly'};

	croak "msg:No files for image creation selected."
		if not  $self->burn_files_selected or not
			keys %{$self->burn_files_selected};

	my $is_image;
	my @files = map  { $is_image = 1 if $_->{is_image}; $_->{path} }
		    sort { $a->{path} cmp $b->{path} }
		    values %{$self->burn_files_selected};

	die "No burn files selected."      if not @files;
	die "File is already an CD image." if $is_image;

	my $cd_type = $self->burn_cd_type;
	
	if ( $cd_type ne 'iso' and $on_the_fly ) {
		croak "Can't burn (S)VCD on the fly";
	}

	my $image_file = $self->cd_image_file;

	my $command;
	if ( $cd_type eq 'iso' ) {
		if ( $on_the_fly and $self->config('burn_estimate_size') ) {
			$command = 'SIZE=$(';
			$command .= $self->config('burn_mkisofs_cmd');
			$command .= " -quiet -print-size".
				" -r -J -jcharset default -l -D -L".
				" -V '".$self->burn_label."'".
				" -abstract '".$self->burn_abstract." ".$self->burn_number."'".
				" ".join(" ", @files );
			$command .= ") && ";
			$command .= "dr_exec ".$self->config('burn_mkisofs_cmd');
			$command .= " -quiet";
			$command .=
				" -r -J -jcharset default -l -D -L".
				" -V '".$self->burn_label."'".
				" -abstract '".$self->burn_abstract." ".$self->burn_number."'".
				" ".join(" ", @files );
		} else {
			$command = "dr_exec ".$self->config('burn_mkisofs_cmd');
			$command .= " -quiet" if $on_the_fly;
			$command .= " -o $image_file" if not $on_the_fly;
			$command .=
				" -r -J -jcharset default -l -D -L".
				" -V '".$self->burn_label."'".
				" -abstract '".$self->burn_abstract." ".$self->burn_number."'".
				" ".join(" ", @files );
		}
	} else {
		$command = "dr_exec ".$self->config('burn_vcdimager_cmd').
			($cd_type eq 'svcd' ? ' --type=svcd' : ' --type=vcd2').
			" --iso-volume-label='".uc($self->burn_label)."'".
			" --info-album-id='".uc($self->burn_abstract." ".$self->burn_number)."'".
			" --cue-file=$image_file.cue".
			" --bin-file=$image_file".
			" ".join(" ", @files );
	}

	$command .= " && echo DVDRIP_SUCCESS" if not $on_the_fly;

	return $command;
}

sub get_burn_command {
	my $self = shift;
	
	croak "msg:No files for burning selected."
		if not  $self->burn_files_selected or not
			keys %{$self->burn_files_selected};
	
	my $cd_type = $self->burn_cd_type;
	
	my $is_image;
	my @files = map  { $is_image = 1 if $_->{is_image}; $_->{path} }
		    sort { $a->{path} cmp $b->{path} }
		    values %{$self->burn_files_selected};

	die "No burn files selected." if not @files;

	my $command;
	if ( $cd_type eq 'iso' ) {
		if ( not $is_image ) {
			$command = $self->get_create_image_command (
				on_the_fly => 1
			);
			$command .= " | ".$self->config('burn_cdrecord_cmd');
		} else {
			$command = "dr_exec ".$self->config('burn_cdrecord_cmd');
		}

		$command .=
			" dev=".$self->config('burn_cdrecord_device').
			" fs=4096k -v".
			" speed=".$self->config('burn_writing_speed').
			" -eject -pad -ignsize";

		$command .= " -dummy" if $self->config('burn_test_mode');

		$command .= ' tsize=${SIZE}s' if ( ( not $is_image ) and $self->config('burn_estimate_size') );
		
		if ( not $is_image ) {
			$command .= " -";
		} else {
			$command .= " $files[0]";
		}
	} else {
		$command = "rm -f $files[0].bin; ln -s $files[0] $files[0].bin && ";

		$command .= "dr_exec ".$self->config('burn_cdrdao_cmd');
		
		if ( $command !~ /\bwrite\b/ ) {
			$command .= " write";
		}

		$command .=
			" --device ".$self->config('burn_cdrecord_device').
			" --speed ".$self->config('burn_writing_speed');

		$command .=
			" --driver ".$self->config('burn_cdrdao_driver')
				if $self->config('burn_cdrdao_driver');

		$command .=
			" --buffers ".$self->config('burn_cdrdao_buffers')
				if $self->config('burn_cdrdao_buffers');

		$command .= " --eject"    if $self->config('burn_cdrdao_eject');
		$command .= " --overburn" if $self->config('burn_cdrdao_overburn');
		$command .= " --simulate" if $self->config('burn_test_mode');

		$command .=
			" $files[0].cue".
			" && rm $files[0].bin";
	}

	$command .= " && echo DVDRIP_SUCCESS";
	
	return $command;
}

sub selected_subtitle {
	my $self = shift;
	return undef if not $self->subtitles;
	return undef if not defined $self->selected_subtitle_id;
	return $self->subtitles->{$self->selected_subtitle_id};
}

sub get_cat_vob_command {
	my $self = shift;

	my $rip_mode = $self->project->rip_mode;

	my $cat;
	if ( $rip_mode eq 'rip' ) {
		$cat = "cat ".$self->vob_dir."/*";

	} elsif ( $rip_mode eq 'dvd' ) {
		$cat =	"dr_exec tccat -i ".$self->config('dvd_device').
			" -T ".$self->tc_title_nr;

	} else {
		$cat =	"dr_exec tccat -i ".$self->project->dvd_image_dir.
			" -T ".$self->tc_title_nr;
	}

	return $cat;
}

sub get_subtitle_grab_images_command {
	my $self = shift;
	
	my $subtitle = $self->selected_subtitle;

	my $timecode = $subtitle->tc_preview_timecode;
	my $cnt      = $subtitle->tc_preview_img_cnt;
	my $sid      = sprintf ("0x%02x", $subtitle->id + 32);

	my $sub_dir  = $self->get_subtitle_preview_dir;
	my $vob_dir  = $self->vob_dir;

	if ( $timecode !~ /^\d\d:\d\d:\d\d$/ ) {
		my $frames  = $timecode + 0;
		my $seconds = int($frames / $self->tc_video_framerate);
		$timecode = $self->format_time ( time => $seconds );
	}

	$cnt   = 0 + $cnt;
	$cnt ||= 1;

	my $cat = $self->get_cat_vob_command;

	my $command =
		"mkdir -p $sub_dir && rm -f $sub_dir/*.{pgm,srtx} && ".
		" $cat | tcextract -x ps1 -t vob -a $sid |".
		" subtitle2pgm -P -C 0 -o $sub_dir/pic -v -e $timecode,$cnt".
		" && echo DVDRIP_SUCCESS";

	return $command;
}

sub get_frame_of_time {
	my $self = shift;
	my %par = @_;
	my ($time, $add) = @par{'time','add'};

	my @t = split (/:/, $time);
	
	my $seconds = $t[0]*3600 + $t[1]*60 + $t[2] + $add;

	my $frame = int ( $seconds * $self->frame_rate );
	
	$frame = 0 if $frame < 0;
	$frame = $self->frames - 1 if $frame >= $self->frames;

	return $frame;
}

sub get_subtitle_test_frame_range {
	my $self = shift;

	my $subtitle = $self->selected_subtitle;
	
	my $image_cnt      = $subtitle->tc_test_image_cnt;
	my $time_code_from = $subtitle->preview_images->[0]->time;
	my $time_code_to   = $subtitle->preview_images->[$image_cnt-1]->time;

	my $frame_from = $self->get_frame_of_time (
		time => $time_code_from,
		add  => -2,
	 );
	my $frame_to   = $self->get_frame_of_time (
		time => $time_code_to,
		add  => 2,
	);

	$frame_to = $frame_from if $frame_to < $frame_from;
	
	return ($frame_from, $frame_to);

}

sub get_subtitle_test_transcode_command {
	my $self = shift;
	
	my $subtitle = $self->selected_subtitle;

	croak "msg:No subtitle selected"
		if not $subtitle;
	croak "msg:You must grab preview images first"
		if not @{$subtitle->preview_images};

	# Safe attribues which will be modified for preview
	# transcode command.
	my @save_attr = qw ( tc_start_frame tc_end_frame tc_multipass tc_psu_core );
	my %old_val;
	foreach my $attr ( @save_attr ) {
		$old_val{$attr} = $self->$attr();
	}

	my ($frame_from, $frame_to) = $self->get_subtitle_test_frame_range;

	$self->set_tc_start_frame ( $frame_from );
	$self->set_tc_end_frame   ( $frame_to   );
	$self->set_tc_multipass   ( 0 );
	$self->set_tc_psu_core    ( 0 );

	$self->set_subtitle_test ( 1 );
	my $command = $self->get_transcode_command;
	$self->set_subtitle_test ( undef );

	# Restored attribues which were modified for preview
	# transcode command.
	my $set;
	foreach my $attr ( @save_attr ) {
		$set = "set_$attr";
		$old_val{$attr} = $self->$set($old_val{$attr});
	}

	return $command;
}

sub get_subtitle_transcode_options {
	my $self = shift;

	my $subtitle = $self->get_render_subtitle;
	
	return "" if not $subtitle;
	
	my $command =
		" -J extsub=".$subtitle->id.
		":".($subtitle->tc_vertical_offset||0).
		":".($subtitle->tc_time_shift||0).
		":".($subtitle->tc_antialias?"0":"1").
		":".($subtitle->tc_postprocess?"1":"0");

	if ( $subtitle->tc_color_manip ) {
		$command .=
			":".($subtitle->tc_color_a||0).
			":".($subtitle->tc_color_b||0).
			":".($subtitle->tc_assign_color_a||0).
			":".($subtitle->tc_assign_color_b||0);
	}

	return $command;
}

sub get_subtitle_preview_dir {
	my $self = shift;

	return sprintf(
		"%s/subtitles/%03d/%02d",
		$self->project->snap_dir,
		$self->nr,
		$self->selected_subtitle_id
	);
}

sub get_render_subtitle {
	my $self = shift;

	return undef if not $self->subtitles;

	foreach my $subtitle ( values %{$self->subtitles} ) {
		return $subtitle if $subtitle->tc_render;
	}

	return undef;	
}

sub info_file {
	my $self = shift;
	
	my $info_file = $self->avi_file;
	
	$info_file =~ s/\.[^.]+$/.dvdrip-info/;
	$info_file .= ".dvdrip-info" if $info_file !~ /\./;

	return $info_file;
}

sub get_transcoded_video_width_height {
	my $self = shift;
	
	my $width  = $self->tc_zoom_width;
	my $height = $self->tc_zoom_height;
	
	$width  -= $self->tc_clip2_left + $self->tc_clip2_right;
	$height -= $self->tc_clip2_top  + $self->tc_clip2_bottom;
	
	return ($width, $height);
}

sub get_subtitle_height {
	my $self = shift;
	
	my $subtitle = $self->get_render_subtitle;
	return 1 if not $subtitle;

	croak "msg:No subtitle selected"
		if not $subtitle;
	croak "msg:You must grab preview images first"
		if not @{$subtitle->preview_images};

	my $height;
	foreach my $image ( @{$subtitle->preview_images} ) {
		$height = $image->height if $height < $image->height;
	}
	
	return $height;
}

sub suggest_subtitle_on_black_bars {
	my $self = shift;
	
	my $subtitle = $self->get_render_subtitle;
	return 1 if not $subtitle;

	croak "msg:No subtitle selected" if not $subtitle;

	my $clip2_top    = 0;
	my $clip2_bottom = 0;
	
	my $width  = $self->tc_zoom_width;
	my $height = $self->tc_zoom_height;

	my $rest = ($height - $clip2_bottom - $clip2_top) % 16;

	if ( $rest ) {
		if ( $rest % 2 ) {
			$clip2_bottom -= int($rest/2) + 1;
			$clip2_top    -= int($rest/2);
		} else {
			$clip2_bottom -= $rest/2;
			$clip2_top    -= $rest/2;
		}
	}

	$self->set_tc_clip2_bottom ( $clip2_bottom );
	$self->set_tc_clip2_top    ( $clip2_top    );

	$subtitle->set_tc_vertical_offset ( 0 );

	return 1;
}

sub suggest_subtitle_on_movie {
	my $self = shift;
	
	my $subtitle = $self->get_render_subtitle;
	return 1 if not $subtitle;

	croak "msg:No subtitle selected" if not $subtitle;

	my $clip2_bottom = $self->tc_clip2_bottom;
	my $zoom_height = $self->tc_zoom_height;
	my $pre_zoom_height = $self->height - $self->tc_clip1_top -
			      $self->tc_clip1_bottom;
	my $scale = $pre_zoom_height / $zoom_height;

	my $shift = int($clip2_bottom * $scale);

	$shift = 0 if $shift < 0;

	$subtitle->set_tc_vertical_offset ( $shift + 4 );

	return 1;
}

sub get_extract_ps1_stream_command {
	my $self = shift;
	my %par = @_;
	my ($subtitle) = @par{'subtitle'};

	my $vob_size = $self->get_vob_size;
	my $vob_dir  = $self->vob_dir;

	my $sid             = sprintf ("0x%x", 32 + $subtitle->id);
	my $vobsub_ps1_file = $subtitle->ps1_file;
	my $ifo_file        = $subtitle->ifo_file ( nr => 0 );

	my $cat = $self->get_cat_vob_command;

	my $command =
		"$cat | ".
		"dr_progress -m $vob_size -i 5 | ".
		"tcextract -x ps1 -t vob -a $sid > $vobsub_ps1_file && ".
		"echo DVDRIP_SUCCESS";
	
	return $command;
}

sub get_create_vobsub_command {
	my $self = shift;
	my %par = @_;
	my  ($subtitle, $start, $end, $file_nr) =
	@par{'subtitle','start','end','file_nr'};

	my $avi_dir  = $self->avi_dir;

	my $sid             = sprintf ("0x%x", 32 + $subtitle->id);
	my $vobsub_prefix   = $subtitle->vobsub_prefix ( file_nr => $file_nr );
	my $vobsub_ifo_file = "$vobsub_prefix.ifo";
	my $vobsub_ps1_file = $subtitle->ps1_file;
	my $ifo_file        = $subtitle->ifo_file ( nr => 0 );

	my $ps1_size = int ( (-s $vobsub_ps1_file) / 1024 / 1024  + 1 );

	my $range = "";
	if ( defined $start and defined $end ) {
		$range = "-e $start,$end,0";
		$ps1_size = int ( ($end-$start)/$self->runtime * $ps1_size + 1 );
		$vobsub_ifo_file = "$vobsub_prefix.ifo";
	}

	my $lang = $subtitle->lang;

	my $command =
		"mkdir -p $avi_dir && ".
		"cp $ifo_file $avi_dir/$vobsub_ifo_file && ".
		"cd $avi_dir && ".
		"chmod 644 $vobsub_ifo_file && ".
		"dr_exec cat $vobsub_ps1_file | ".
		"dr_progress -m $ps1_size -i 1 | ".
		"subtitle2vobsub $range".
		" -i $vobsub_ifo_file ".
		" -o $vobsub_prefix &&".
		"sed 's/^id: /id: $lang/' < $vobsub_prefix.idx > vobsub$$.tmp && ".
		"mv vobsub$$.tmp $vobsub_prefix.idx && ".
		"echo DVDRIP_SUCCESS";

	if ( $self->has ( "rar" ) ) {
		my $rar = $self->config('rar_command');
		$command .=
			" && $rar a $vobsub_prefix $vobsub_prefix.{idx,ifo,sub} && ".
			"rm $vobsub_prefix.{idx,ifo,sub}";
	}
	
	return $command;
}

sub get_view_vobsub_command {
	my $self = shift;
	my %par = @_;
	my ($subtitle) = @par{'subtitle'};

	my $avi_dir  = $self->avi_dir;
	my $vob_dir  = $self->vob_dir;

	my $vobsub_prefix   = $subtitle->vobsub_prefix;
	
	my $command =
		"cd $avi_dir && ".
		"mplayer -vobsub $vobsub_prefix -vobsubid 0 $vob_dir/*";

	return $command;
}

sub get_split_files {
	my $self = shift;

	my $mask = $self->avi_file;
	$mask =~ s/\.([^\.]+)$//;
	my $ext = $1;
	$mask .= "-*.$ext";

	my @files = glob($mask);
	
	return \@files;
}

sub get_count_frames_in_files_command {
	my $self = shift;

	my $files = $self->get_split_files;

	my $command = "echo START";

	foreach my $file ( @{$files} ) {
		if ( $self->is_ogg ) {
			$command .= " && echo 'DVDRIP:OGG:$file' frames=\$(";
			$command .=
				" ogminfo -v -v $file 2>&1 |".
				" grep 'v1.*granulepos' | wc -l )";
		} else {
			$command .= " && echo 'DVDRIP:AVI:$file' \$(";
			$command .=
				" tcprobe -i $file 2>&1 | grep frames= )";
		}
	}

	$command .= " && echo DVDRIP_SUCCESS";

	return $command;
}

sub has_vobsub_subtitles {
	my $self = shift;
	
	return 0 if not $self->subtitles;

	foreach my $subtitle ( values %{$self->subtitles} ) {
		return 1 if $subtitle->tc_vobsub;
	}
	
	return 0;
}

# transcode -T 1,2 -i /dev/dvd -x null -y null,wav -o test1.wav

sub get_create_wav_command {
	my $self = shift;
	
	return "echo 'No audio channel selected'"
		if $self->audio_channel == -1;
	
	my $audio_wav_file = $self->audio_wav_file;
	my $dir            = dirname($audio_wav_file);
	my $nr             = $self->nr;
	my $source         = $self->transcode_data_source;
	my $audio_nr       = $self->audio_track->tc_nr;

	my $source_options = $self->data_source_options;
	$source_options->{x} = "null";

	my $command =
		"mkdir -p $dir &&".
		" dr_exec transcode -a $audio_nr ".
		" -y null,wav -u 100 -o $audio_wav_file";

	$command .= " -$_ $source_options->{$_}" for keys %{$source_options};

	$command .= " -d" if $self->audio_track->type eq 'lpcm';

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

	$command .= " && echo DVDRIP_SUCCESS";

	return $command;	
}

sub check_svcd_geometry {
	my $self = shift;
	
	return if not $self->tc_container eq 'vcd';
	
	my $codec = $self->tc_video_codec;
	my $mode  = $self->video_mode;
	
	my $width =
		($self->tc_zoom_width || $self->width) -
		$self->tc_clip2_left - $self->tc_clip2_right;

	my $height =
		($self->tc_zoom_height || $self->height) -
		$self->tc_clip2_top - $self->tc_clip2_bottom;
	
	my %valid_values = (
		"VCD:pal:width"  	=> 352,
		"VCD:pal:height" 	=> 288,
		"VCD:ntsc:width"  	=> 352,
		"VCD:ntsc:height" 	=> 240,
		"SVCD:pal:width"  	=> 480,
		"SVCD:pal:height" 	=> 576,
		"SVCD:ntsc:width"  	=> 480,
		"SVCD:ntsc:height" 	=> 480,
	);
	
	my $should_width  = $valid_values{"$codec:$mode:width"};
	my $should_height = $valid_values{"$codec:$mode:height"};
	
	$mode = uc($mode);
	
	if ( $width  != $should_width or $height != $should_height ) {
		return	"Your frame size isn't conform to the standard,\n".
			"which is ${should_width}x${should_height} for $codec/$mode, but you ".
			"configured ${width}x${height}."
	}

	return;
}

1;
