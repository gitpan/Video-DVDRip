# $Id: Split.pm,v 1.4 2002/03/30 11:19:36 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::Split;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub info {
	return "split avi file";
}

sub start {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get audio processing command
	$project->set_assigned_job ( $self );
	my $command = $title->get_split_command;
	$project->set_assigned_job ( undef );
	
	$self->set_progress_frames_cnt ($title->frames);

	my $successful_finished = 0;
	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /\(\d+-(\d+)\)/ ) {
				$self->set_progress_frames ($1);
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
