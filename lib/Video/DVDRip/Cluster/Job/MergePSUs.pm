# $Id: MergePSUs.pm,v 1.5 2002/06/23 21:43:35 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergePSUs;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub type {
	return "psu merge";
}

sub info {
	my $self = shift;

	return "merge program stream units";
}

sub start {
	my $self = shift;

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_psu_command;
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
