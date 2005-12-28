# $Id: ReadDVDToc.pm,v 1.2 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::ReadDVDToc;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1]	}

sub type {
	return "read_dvd_toc";
}

sub info {
	__"Reading TOC";
}

sub init {
	my $self = shift;
	
	$self->set_need_output(1);
	$self->set_progress_show_percent(0);

	1;
}

sub command {
	my $self = shift;

	my $dvd_device = $self->project->dvd_device;
	
	my $command =
		"dvdrip-exec lsdvd -a -n -c -s -v -Op $dvd_device 2>/dev/null ".
		"&& echo DVDRIP_SUCCESS";

	return $command;
}

sub parse_output {
	my $self = shift;
	my ($buffer) = @_;

	$self->set_operation_successful (1)
		if $buffer =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift;

	Video::DVDRip::Probe->analyze_lsdvd (
		probe_output    => $self->pipe->output,
		project         => $self->project,
		cb_title_probed	=> $self->task->cb_title_probed,
	);

	$self->log (__"Successfully read DVD TOC");
	
	1;
}

1;
