# $Id: Rip.pm,v 1.12 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::Rip;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

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

	my $info = __"Ripping";
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

	$info .= ", ".__x("chapter {chapter}", chapter => $self->chapter) if $self->chapter;

	return $info;
}

sub init {
	my $self = shift;
	
	my $title   = $self->title;
	my $chapter = $self->chapter;
	
	$self->set_progress_show_fps ( 1 );
	
	if ( not $chapter or $self->title->tc_use_chapter_mode eq 'all' ) {
		$self->set_progress_max ( $title->frames );

	} elsif ( $chapter and $self->title->chapter_frames->{$chapter} ) {
		$self->set_progress_max (
			$self->title->chapter_frames->{$chapter}
		);

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
	
	my $count = 0;

	$count = 1 if $self->chapter and
		      $self->chapter != $title->get_first_chapter;

	$title->analyze_scan_output (
		output => $self->pipe->output,
		count  => $count,
	);
	
	my $audio_tracks  = $title->audio_tracks;
	
	$_->set_tc_target_track(-1) for @{$audio_tracks};
	$title->audio_track->set_tc_target_track(0);

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
				"transcode/libdvdread installation, resp. a problem with\n".
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
