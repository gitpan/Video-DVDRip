# $Id: Title.pm,v 1.33 2001/12/11 22:16:04 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Title;

use base Video::DVDRip::Base;

use Video::DVDRip::Scan;
use Video::DVDRip::Probe;

use Carp;
use strict;

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

sub volume_rescale		{ shift->scan_result->volume_rescale	}

sub nr				{ shift->{nr}				}
sub size			{ shift->{size}				}
sub audio_channel		{ shift->{audio_channel}		}
sub scan_result			{ shift->{scan_result}			}
sub probe_result		{ shift->{probe_result}			}
sub rip_time			{ shift->{rip_time}			}
sub scan_time			{ shift->{scan_time}			}
sub probe_time			{ shift->{probe_time}			}
sub preset			{ shift->{preset}			}
sub preview_frame_nr		{ shift->{preview_frame_nr}		}
sub files			{ shift->{files}			}

sub set_nr			{ shift->{nr}			= $_[1] }
sub set_size			{ shift->{size}			= $_[1] }
sub set_audio_channel		{ shift->{audio_channel}	= $_[1] }
sub set_scan_result		{ shift->{scan_result}		= $_[1] }
sub set_probe_result		{ shift->{probe_result}		= $_[1] }
sub set_rip_time		{ shift->{rip_time}		= $_[1] }
sub set_scan_time		{ shift->{scan_time}		= $_[1] }
sub set_probe_time		{ shift->{probe_time}		= $_[1] }
sub set_preset			{ shift->{preset}		= $_[1] }
sub set_preview_frame_nr	{ shift->{preview_frame_nr}	= $_[1] }

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
sub tc_volume_rescale		{ shift->{tc_volume_rescale}      	}
sub tc_target_size		{ shift->{tc_target_size}		}
sub tc_disc_cnt 	    	{ shift->{tc_disc_cnt}			}
sub tc_disc_size	    	{ shift->{tc_disc_size}			}
sub tc_start_frame	    	{ shift->{tc_start_frame}		}
sub tc_end_frame	    	{ shift->{tc_end_frame}			}
sub tc_fast_resize	    	{ shift->{tc_fast_resize}		}
sub tc_multipass	    	{ shift->{tc_multipass}			}
sub tc_title_nr	    		{ $_[0]->{tc_title_nr} || $_[0]->{nr}	}

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
sub set_tc_volume_rescale	{ shift->{tc_volume_rescale}   	= $_[1]	}
sub set_tc_target_size		{ shift->{tc_target_size}    	= $_[1]	}
sub set_tc_disc_cnt		{ shift->{tc_disc_cnt}    	= $_[1]	}
sub set_tc_disc_size		{ shift->{tc_disc_size}    	= $_[1]	}
sub set_tc_start_frame		{ shift->{tc_start_frame}    	= $_[1]	}
sub set_tc_end_frame		{ shift->{tc_end_frame}    	= $_[1]	}
sub set_tc_fast_resize		{ shift->{tc_fast_resize}    	= $_[1]	}
sub set_tc_multipass		{ shift->{tc_multipass}    	= $_[1]	}
sub set_tc_title_nr	    	{ shift->{tc_title_nr}    	= $_[1]	}

sub vob_dir {
	my $self = shift; $self->trace_in;
	
	return 	$self->project->vob_dir."/".
		$self->nr;
}

sub avi_file {
	my $self = shift; $self->trace_in;
	
	return 	$self->project->avi_dir."/".
		$self->project->name."-".
		$self->nr.".avi";
}

sub preview_filename {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	return 	$self->project->snap_dir."/".
		$self->project->name."-".
		$self->nr."-preview-$type.jpg";
}

sub new {
	my $class = shift;
	my %par = @_;
	my ($nr, $project) = @par{'nr','project'};

	my $self = {
		project	        => $project,
		nr              => $nr,
		size            => 0,
		files           => [],
		audio_channel   => 0,
		scan_result     => undef,
		probe_result    => undef,
		rip_time        => undef,
		scan_time       => undef,
		probe_time      => undef,
		tc_clip1_top	=> 0,
		tc_clip1_bottom	=> 0,
		tc_clip1_left	=> 0,
		tc_clip1_right	=> 0,
		tc_clip2_top	=> 0,
		tc_clip2_bottom	=> 0,
		tc_clip2_left	=> 0,
		tc_clip2_right	=> 0,
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

#---------------------------------------------------------------------
# Methods for Ripping
#---------------------------------------------------------------------

sub is_ripped {
	my $self = shift;
	
	my $vob_dir    = $self->vob_dir;
	my $name       = $self->project->name;
	
	return -f "$vob_dir/$name-001.vob";
}

sub get_rip_command {
	my $self = shift; $self->trace_in;

	$self->project->check_installation;

	my $nr         = $self->tc_title_nr;
	my $name       = $self->project->name;
	my $dvd_device = $self->project->dvd_device;
	my $vob_dir    = $self->vob_dir;

	if ( not -d $vob_dir ) {
		mkpath ([ $vob_dir ], 0, 0755)
			or croak "Can't mkpath directory '$vob_dir'";
	}

	my $command = "rm -f $vob_dir/$name-???.vob;\n".
	           "tccat -t dvd -T $nr,-1 -i $dvd_device ".
	           "| splitpipe 1024 $vob_dir/$name vob >/dev/null";

	return $command;
}

sub rip {
	my $self = shift; $self->trace_in;

	$self->system (
		command => $self->get_rip_command,
	);
	
	$self->set_rip_time (time);

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
	
	$self->set_rip_time (time);

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

	close $fh;
	croak ($message) if $?;

	$self->set_rip_time (time);
	
	1;
}

#---------------------------------------------------------------------
# Methods for Scanning
#---------------------------------------------------------------------

sub get_scan_command {
	my $self = shift; $self->trace_in;

	$self->project->check_installation;

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
	
	$self->set_scan_time (time);

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
	
	$self->set_scan_time (time);

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

	$self->set_scan_time (time);

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

	$self->set_tc_volume_rescale ( $self->volume_rescale );

	1;
}

#---------------------------------------------------------------------
# Methods for Ripping and Scanning
#---------------------------------------------------------------------

sub get_rip_and_scan_command {
	my $self = shift; $self->trace_in;

	$self->project->check_installation;

	my $nr            = $self->tc_title_nr;
	my $audio_channel = $self->audio_channel;
	my $name          = $self->project->name;
	my $dvd_device    = $self->project->dvd_device;
	my $vob_dir    	  = $self->vob_dir;

	if ( not -d $vob_dir ) {
		mkpath ([ $vob_dir ], 0, 0755)
			or croak "Can't mkpath directory '$vob_dir'";
	}

	my $command =
	       "rm -f $vob_dir/$name-???.vob;\n".
	       "tccat -t dvd -T $nr,-1 -i $dvd_device ".
	       "| splitpipe 1024 $vob_dir/$name vob ".
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

	$self->set_rip_time (time);
	$self->set_scan_time (time);
	
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
		command => $self->get_rip_and_scan_command,
		callback => $callback,
		catch_output => 1,
	);

	$self->set_rip_time (time);
	$self->set_scan_time (time);

	$self->analyze_scan_output (
		output => $output
	);

	1;
}

sub rip_and_scan_async_start {
	my $self = shift; $self->trace_in;
	
	return $self->popen (
		command => $self->get_rip_and_scan_command,
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

	$self->set_rip_time (time);
	$self->set_scan_time (time);
	
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
	
	$self->project->check_installation;

	my $nr            = $self->tc_title_nr;
	my $dvd_device    = $self->project->dvd_device;

	return "tcprobe -i $dvd_device -T $nr";
}

sub probe {
	my $self = shift; $self->trace_in;
	
	my $dvd_device    = $self->project->dvd_device;

	my $output = $self->system (
		command => $self->get_probe_command
	);
	
	$self->set_probe_time(time);

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
	
	$self->set_probe_time (time);

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
	
	$self->set_probe_time (time);

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
# Methods for Transcoding
#---------------------------------------------------------------------

sub suggest_transcode_options {
	my $self = shift; $self->trace_in;

	$self->set_tc_viewing_angle ( 1 );
	$self->set_tc_use_yuv_internal ( 1 );
	$self->set_tc_video_codec ( "divx4" );
	$self->set_tc_audio_codec ( "" );
	$self->set_tc_audio_bitrate ( 128 );
	$self->set_tc_target_size ( 1400 );
	$self->set_tc_disc_size ( 700 );
	$self->set_tc_disc_cnt ( 2 );

	$self->suggest_video_bitrate;

	return 1;
	
	# this works bad... :(

	if ( $self->aspect_ratio eq '16:9' and not $self->letterboxed ) {
		# anamorph encoded
		$self->print_debug ("anamorph 16:9 encoding detected...");
		$self->set_tc_zoom_width (768);
		$self->set_tc_zoom_height(432);

	} elsif ( $self->aspect_ratio eq '16:9' ) {
		# aspect ratio is Ok, we cut off the black bars
		# (this should probably be adjusted later)
		$self->print_debug ("letterboxed 16:9 encoding detected...");
		$self->set_tc_clip1_top (80);
		$self->set_tc_clip1_bottom (80);
		$self->set_tc_clip1_left (16);
		$self->set_tc_clip1_right (16);

	} elsif ( $self->aspect_ratio eq '4:3' ) {
		# nothing special here, we'll do a 1:1 transcoding
		$self->print_debug ("4:3 encoding detected...");

	} else {
		# Can't suggest parameters for this DVD
	}
	
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

	$self->project->check_installation;

	my $nr       = $self->nr;
	my $avi_file = $self->avi_file;

	my $command =
		"transcode".
		" -i ".$self->project->vob_dir."/$nr".
		" -o $avi_file".
		" -x vob".
		" -a ".$self->audio_channel.
		" -w ".int($self->tc_video_bitrate).",250,100";
	
	if ( $self->tc_start_frame ne '' and
	     $self->tc_end_frame ne '' ) {
		$command .= " -c ".$self->tc_start_frame."-".
			    $self->tc_end_frame;
	} else {
		$command .= " -c 0-".$self->frames;
	}

	$command .= " -y ".$self->tc_video_codec;
	$command .= ",".$self->tc_audio_codec
		if $self->tc_audio_codec ne '';
	$command .= " -F ".$self->tc_video_af6_codec
		if $self->tc_video_af6_codec ne '';

	$command .= " -V "
		if $self->tc_use_yuv_internal;
	$command .= " -s ".$self->tc_volume_rescale
		if $self->tc_volume_rescale ne '';
	$command .= " -b ".$self->tc_audio_bitrate
		if $self->tc_audio_bitrate ne '';
	$command .= " -C ".$self->tc_anti_alias
		if $self->tc_anti_alias;
	$command .= " -I ".$self->tc_deinterlace
		if $self->tc_deinterlace;

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
		my $dir = dirname($self->preview_filename);
		$command = "cd $dir; $command";
		$command .= " -R $pass";
	}

	my $avi_dir = dirname $avi_file;

	if ( not -d $avi_dir ) {
		mkpath ([ $avi_dir ], 0, 0755)
			or croak "Can't mkpath directory '$avi_dir'";
	}
	
print "$command\n";

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

	if ( ($width_n != 0 and $zoom_width % 32 != 0 and $width % 32 != 0) or
	     ($height_n != 0 and $zoom_height % 32 != 0 and $height % 32 != 0) 
	     or () ) {
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
	
	$self->project->check_installation;

	my $avi_file = $self->avi_file;
	my $size     = $self->tc_disc_size;

	croak "No AVI file found: '$avi_file'" if not -f $avi_file;

	if ( -s $avi_file < $size*1024*1024 ) {
		warn "$avi_file is smaller than $size MB, no need to split.";
		return;
	}

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

sub get_take_snapshot_command {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($frame) = @par{'frame'};

	$self->project->check_installation;

	my $nr      = $self->nr;
	my $tmp_dir = "/tmp/lightrip$$.ppm";
	
	my $command =
	       "mkdir $tmp_dir; ".
	       "cd $tmp_dir; ".
	       "transcode".
	       " -z -k -i ".$self->project->vob_dir."/$nr".
	       " -o snapshot".
	       " -x vob -y ppm -c $frame-".($frame+1);

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

sub convert_snapshot {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($filename) = @par{'filename'};

	my $tmp_dir = "/tmp/lightrip$$.ppm";

	my $dirname = dirname ($filename);

	my $command =
		"mkdir -p $dirname; ".
		"convert".
		" -size ".$self->width."x".$self->height.
		" $tmp_dir/snapshot00000.ppm $filename;".
		" rm -r $tmp_dir";

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
	
	$self->set_rip_time(undef);
	
	1;
}

1;
