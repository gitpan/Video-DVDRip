# $Id: Title.pm,v 1.62 2002/03/03 22:02:00 joern Exp $

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

sub volume_rescale		{ shift->scan_result->volume_rescale	}

sub nr				{ shift->{nr}				}
sub size			{ shift->{size}				}
sub audio_channel		{ shift->{audio_channel}		}
sub scan_result			{ shift->{scan_result}			}
sub probe_result		{ shift->{probe_result}			}
sub preset			{ shift->{preset}			}
sub preview_frame_nr		{ shift->{preview_frame_nr}		}
sub files			{ shift->{files}			}
sub actual_chapter		{ shift->{actual_chapter}		}
sub program_stream_units	{ shift->{program_stream_units}		}

sub set_nr			{ shift->{nr}			= $_[1] }
sub set_size			{ shift->{size}			= $_[1] }
sub set_audio_channel		{ shift->{audio_channel}	= $_[1] }
sub set_scan_result		{ shift->{scan_result}		= $_[1] }
sub set_probe_result		{ shift->{probe_result}		= $_[1] }
sub set_preset			{ shift->{preset}		= $_[1] }
sub set_preview_frame_nr	{ shift->{preview_frame_nr}	= $_[1] }
sub set_actual_chapter		{ shift->{actual_chapter}	= $_[1] }
sub set_program_stream_units	{ shift->{program_stream_units}	= $_[1] }

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
sub tc_volume_rescale		{ shift->{tc_volume_rescale}      	}
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
sub set_tc_volume_rescale	{ shift->{tc_volume_rescale}   	= $_[1]	}
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

	if ( $self->tc_use_chapter_mode ) {
		return 	sprintf("%s/%03d/%s-%03d-C%03d.avi", 
			$self->project->avi_dir,
			$self->nr,
			$self->project->name,
			$self->nr,
			$self->actual_chapter);
	} else {
		return 	sprintf("%s/%03d/%s-%03d.avi",
			$self->project->avi_dir,
			$self->nr,
			$self->project->name,
			$self->nr);
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
		$self->tc_use_chapter_mode ? $self->actual_chapter : -1;

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
	
	1;
}

sub rip_with_callback {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($callback) = @par{'callback'};
	
	$self->popen (
		command => $self->get_rip_command,
		callback => $callback,
	);
	
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

	$self->set_scan_result (
		Video::DVDRip::Scan->analyze (
			scan_output => $output,
		)

	);

	if ( $self->tc_use_chapter_mode ) {
		$self->set_tc_volume_rescale ( undef );
	} else {
		$self->set_tc_volume_rescale ( $self->volume_rescale );
	}

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
		$self->tc_use_chapter_mode ? $self->actual_chapter : -1;

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

	$output = "\n\nOutput was:\n\n$output" if $output;

	my $message =   "Error executing:\n\n".
			$self->get_probe_command.
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

	if ( @{$self->probe_result->audio_tracks} ) {
		$self->set_audio_channel(0);
	} else {
		$self->set_audio_channel(-1);
	}

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
	$self->set_tc_target_size ( 1400 );
	$self->set_tc_disc_size ( 700 );
	$self->set_tc_disc_cnt ( 2 );
	$self->set_tc_video_framerate (
		$self->video_mode eq 'pal' ? 25 : 23.976
	);
	$self->suggest_video_bitrate;

	1;
}

sub suggest_video_bitrate {
	my $self = shift;
	
	my $target_size = $self->tc_target_size;

	$target_size = 4000 if $target_size > 4000;

	my $frames        = $self->frames;
	my $fps           = $self->frame_rate;

	my $audio_bitrate = $self->tc_audio_bitrate;

	my $runtime = $frames/$fps;
	my $audio_size = int($runtime * $audio_bitrate / 1024 / 8);
	my $video_size = $target_size - $audio_size;

	my $video_bitrate = int($video_size/$runtime/1000*1024*1024*8);
	$video_bitrate = 6000 if $video_bitrate > 6000;

	$self->set_tc_video_bitrate ( $video_bitrate );

	1;
}

sub get_transcode_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($pass) = @par{'pass'};

	my $nr       = $self->nr;
	my $avi_file = $self->avi_file;

	my $nice;
	$nice = "/usr/bin/nice -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $command =
		$nice.
		"transcode".
		" -i ".$self->vob_dir.
		" -a ".$self->audio_channel.
		" -w ".int($self->tc_video_bitrate).",250,100";

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

	$command .= ",".$self->tc_audio_codec
		if $self->tc_audio_codec ne '';
	$command .= " -F ".$self->tc_video_af6_codec
		if $self->tc_video_af6_codec ne '';

	$command .= " -b ".$self->tc_audio_bitrate
		if $self->tc_audio_bitrate ne '';

	if ( $self->tc_ac3_passthrough ) {
		$command .=
			" -A -N ".
			$self->audio_tracks
			     ->[$self->audio_channel]
			     ->{tc_option_n};
	} else {
		$command .= " -s ".$self->tc_volume_rescale
			if $self->tc_volume_rescale ne '';
	}

	$command .= " -V "
		if $self->tc_use_yuv_internal;
	$command .= " -C ".$self->tc_anti_alias
		if $self->tc_anti_alias;
	$command .= " -I ".$self->tc_deinterlace
		if $self->tc_deinterlace;

	$command .= " -f ".$self->tc_video_framerate
		if $self->tc_video_framerate;

	if ( $self->video_mode eq 'ntsc' ) {
		$command .= " -g 720x480 -M 2";
	}

	$command .= " -J preview=xv" if $self->tc_preview;

	my $clip1 = $self->tc_clip1_top.",".
		    $self->tc_clip1_left.",".
		    $self->tc_clip1_bottom.",".
		    $self->tc_clip1_right;

	$command .= " -j $clip1"
		if $clip1 =~ /^\d+,\d+,\d+,\d+$/ and $clip1 ne '0,0,0,0';

	my $clip2 = $self->tc_clip2_top.",".
		    $self->tc_clip2_left.",".
		    $self->tc_clip2_bottom.",".
		    $self->tc_clip2_right;

	$command .= " -Y $clip2"
		if $clip2 =~ /^\d+,\d+,\d+,\d+$/ and $clip2 ne '0,0,0,0';

	if ( not $self->tc_fast_resize ) {
		my $zoom = $self->tc_zoom_width."x".$self->tc_zoom_height;
		$command .= " -Z $zoom"
			if $zoom =~ /^\d+x\d+$/;

	} else {
		my ($width_n, $height_n, $err_div32, $err_shrink_expand) =
			$self->get_fast_resize_options;

		if ( $err_div32 ) {
			croak "When using fast resize: Clip1 and Zoom size must be divsible by 32";
		}

		if ( $err_shrink_expand ) {
			croak "When using fast resize: Width and height must both shrink or expand";
		}

		if ( $width_n * $height_n >= 0 ) {
			if ( $width_n > 0 or $height_n > 0 ) {
				$command .= " -X $height_n,$width_n";
			} else {
				$width_n  = abs($width_n);
				$height_n = abs($height_n);
				$command .= " -B $height_n,$width_n";
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
		$command .= " -y ".$self->tc_video_codec;
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

	my $width = $self->width - $self->tc_clip1_left
				 - $self->tc_clip1_right;
	my $height = $self->height - $self->tc_clip1_top
				   - $self->tc_clip1_bottom;

	my $zoom_width  = $self->tc_zoom_width;
	my $zoom_height = $self->tc_zoom_height;

	my $width_n  = ($zoom_width  - $width)  / 32;
	my $height_n = ($zoom_height - $height) / 32;

	my ($err_div32, $err_shrink_expand);

	$self->print_debug("width_n=$width_n width=$width width \% 32 = ", $width % 32);
	$self->print_debug("height_n=$height_n height=$height height \% 32 = ", $height % 32);

	if ( ($width_n != 0 and ( $zoom_width % 32 != 0 or $width % 32 != 0) ) or
	     ($height_n != 0 and ( $zoom_height % 32 != 0 or $height % 32 != 0 ) ) ) {
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
# Methods for AVI Splitting
#---------------------------------------------------------------------

sub get_split_command {
	my $self = shift; $self->trace_in;

	my $avi_file = $self->target_avi_file;
	my $size     = $self->tc_disc_size;

	my $command = "avisplit -s $size -i $avi_file";
	
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

sub snapshot_filename	   { shift->{snapshot_filename}  	 }
sub set_snapshot_filename  { shift->{snapshot_filename}  = $_[1] }

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

	return	"mkdir -m 0775 -p $dirname; ".
		"convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot00000.ppm $filename;".
		" rm -r $tmp_dir";

}
sub convert_snapshot {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($filename) = @par{'filename'};

	my $command = $self->get_convert_snapshot_command (
		filename => $filename
	);
	
	$self->system (
		command => $command
	);

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
