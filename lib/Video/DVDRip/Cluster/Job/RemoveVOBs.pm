# $Id: RemoveVOBs.pm,v 1.4 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
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

sub command {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get remove vobs command
	$project->set_assigned_job ( $self );
	my $command = $title->get_remove_vobs_command;
	$project->set_assigned_job ( undef );
	
	return $command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;
	
	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;
}

1;
