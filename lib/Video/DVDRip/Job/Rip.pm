# $Id: Rip.pm,v 1.4 2002/11/01 13:32:30 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::Rip;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub set_chapter			{ shift->{chapter}		= $_[1]	}

sub type {
	return "rip";
}

sub info {
	my $self = shift;

	my $info = "Ripping - title #".$self->title->nr;

	$info .= ", chapter ".$self->chapter if $self->chapter;

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$self->set_progress_show_fps ( 1 );
	
	if ( not $self->chapter or $self->title->tc_use_chapter_mode eq 'all' ) {
		$self->set_progress_max ( $title->frames );
	} else {
		$self->set_progress_show_percent( 0 );
		$self->set_progress_max ( 0 );
		
	}

	1;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	return 0;
}

sub get_diskspace_freed {
	return 0;
}

sub command {
	my $self = shift;

	my $title  = $self->title;
	
	$title->set_actual_chapter ( $self->chapter );
	my $command = $title->get_rip_and_scan_command;
	$title->set_actual_chapter (undef);
	
	return $command;
}

sub parse_output {
	my $self = shift;
	my ($buffer) = @_;

	my $frames = $self->progress_cnt;
	$self->set_progress_start_time(time) if not $frames;
	++$frames while $buffer =~ /^[\d\t ]+$/gm;
	$self->set_progress_cnt ($frames);

	$self->set_operation_successful (1)
		if $buffer =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift;
	
	my $title = $self->title;
	
	$title->analyze_scan_output (
		output => $self->pipe->output
	);
	
	my $tc_audio_tracks = $title->tc_audio_tracks;
	my $audio_channel   = $title->audio_channel;
	
	$_->set_tc_target_track(-1) for @{$tc_audio_tracks};
	$tc_audio_tracks->[$audio_channel]->set_tc_target_track(0);

	$title->set_actual_chapter($self->chapter);

	if ( $self->chapter ) {
		$title->set_chapter_length ( $self->chapter );

		if ( $title->chapter_frames->{$self->chapter} < 10 ) {
			$self->set_error_message (
				"Chapter ".$self->chapter.
				" is too small and useless. You ".
				" should deselect it."
			);
			$self->set_state ("aborted");
			$title->set_actual_chapter(undef);
			return 1;
		}

		if ( $self->chapter == $title->get_last_chapter ) {
			$title->probe_audio;
			$title->calc_program_stream_units;
			$title->suggest_transcode_options;
		}
	} else {
		my $job_frames   = $self->progress_cnt;
		my $title_frames = $title->frames; 

		if ( $job_frames < $title_frames - 200 ) {
			$self->set_error_message (
				"WARNING: it seems that transcode ripping stopped short.\n".
				"The movie has $title_frames frames, but only $job_frames\n".
				"were ripped. This is most likely a problem with your\n".
				"transcode/libdvdread/libdvdcss installation, resp. with\n".
				"this specific DVD."
			);
		}

		$title->set_frames($job_frames);
		$title->probe_audio;
		$title->calc_program_stream_units;
		$title->suggest_transcode_options;
	}

	$title->set_actual_chapter(undef);
	
	1;
}

1;
