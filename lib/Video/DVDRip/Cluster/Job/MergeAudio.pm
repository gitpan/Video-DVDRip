# $Id: MergeAudio.pm,v 1.4 2002/03/29 16:52:31 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergeAudio;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub type {
	return "multiplex video and audio";
}

sub info {
	my $self = shift;

	return "multiplex video and audio";
}

sub start {
	my $self = shift;

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_audio_command;
	$project->set_assigned_job ( undef );

	$self->set_progress_frames_cnt ($title->frames);

	my $successful_finished = 0;
	my $first = 1;
	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /\(\d+-(\d+)\)/ ) {
				$self->set_progress_start_time(time) if $first;
				$self->set_progress_frames ($1);
				$first = 0;
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
