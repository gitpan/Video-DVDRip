# $Id: RemoveVOBs.pm,v 1.1 2002/03/03 15:09:28 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::RemoveVOBs;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub info {
	return "remove vob files";
}

sub start {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get remove vobs command
	$project->set_assigned_job ( $self );
	my $command = $title->get_remove_vobs_command;
	$project->set_assigned_job ( undef );
	
	my $successful_finished = 0;
	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /DVDRIP_SUCCESS/ ) {
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

sub calc_progress {
	my $self = shift;

	return "removing VOB files";
}

1;
