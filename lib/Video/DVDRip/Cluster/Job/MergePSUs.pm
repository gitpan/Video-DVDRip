# $Id: MergePSUs.pm,v 1.7 2002/10/06 11:42:39 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
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

sub init {
	my $self = shift;

	$self->set_progress_max ($self->title->frames);
	
	1;
}

sub command {
	my $self = shift;

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_psu_command;
	$project->set_assigned_job ( undef );

	return $command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $line =~ /\(\d+-(\d+)\)/ ) {
		$self->set_progress_cnt ($1);
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;
}
 
1;
