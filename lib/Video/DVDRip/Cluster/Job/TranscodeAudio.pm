# $Id: TranscodeAudio.pm,v 1.2 2002/03/17 18:53:25 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::TranscodeAudio;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub type {
	return "transcode audio";
}

sub info {
	my $self = shift;

	return  "transcode audio";
}

sub start {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get transcode command
	$project->set_assigned_job ( $self );
	my $command = $title->get_transcode_audio_command;
	$project->set_assigned_job ( undef );

	# start command
	my $frames_cnt;
	my $successful_finished = 0;

	$self->set_progress_frames (0);

	$frames_cnt = $self->project->title->frames;

	$self->set_progress_frames_cnt ($frames_cnt);

	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /split.*?frames.*?-c\s+\d+-(\d+)/ ) {
				$self->set_progress_frames_cnt ($1);
				$frames_cnt = $1;
				$self->set_progress_start_time(time);

			} elsif ( $line =~ /\[\d{6}-(\d+)\]/ ) {
				$self->set_progress_frames($1);

			} elsif ( $line =~ /DVDRIP_SUCCESS/ ) {
				$successful_finished = 1;
			}
		},
		cb_finished  => sub {
			if ( $successful_finished ) {
				$self->commit_job;
			} else {
				$self->abort_job;
			}
		},
	);
	
	1;
}

1;
