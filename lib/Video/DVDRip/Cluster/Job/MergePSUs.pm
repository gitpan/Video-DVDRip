# $Id: MergePSUs.pm,v 1.11 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergePSUs;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

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
