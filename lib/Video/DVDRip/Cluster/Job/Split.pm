# $Id: Split.pm,v 1.8 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::Split;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job::Split;

use Carp;
use strict;

sub command {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get audio processing command
	$project->set_assigned_job ( $self );
	my $command = $title->get_split_command;
	$project->set_assigned_job ( undef );

	return $command;
}

sub commit {
	1;
}

1;
