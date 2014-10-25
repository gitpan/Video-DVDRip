# $Id: BitrateCalc.pm,v 1.5 2005/04/24 12:30:39 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::BitrateCalc;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub bc				{ shift->{bc}				}
sub set_bc			{ shift->{bc}			= $_[1]	}

sub info {
	return "calc video bitrate";
}

sub command {
	my $self = shift;

	$self->set_operation_successful ( 1 );

	return "echo DVDRIP_SUCCESS";
}

sub commit {
	my $self = shift;
	
	my $bc    = $self->bc;
	my $title = $self->project->title;

	$bc->set_title ( $title );
	$title->set_tc_video_bitrate ( $bc->calculate );
	$bc->set_title ( undef );
	
	1;
}

1;
