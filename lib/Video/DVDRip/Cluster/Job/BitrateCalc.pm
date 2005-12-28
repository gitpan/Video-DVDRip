# $Id: BitrateCalc.pm,v 1.6 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::BitrateCalc;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

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
