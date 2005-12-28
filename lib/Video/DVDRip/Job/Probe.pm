# $Id: Probe.pm,v 1.6 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::Probe;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub type {
	return "probe";
}

sub info {
	my $self = shift;

	my $info = __"Probing";
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

	return $info;
}

sub init {
	my $self = shift;
	
	$self->set_need_output(1);
	$self->set_progress_cnt($self->title->nr);
	$self->set_progress_show_fps(0);
	$self->set_progress_show_elapsed(0);
	$self->set_progress_show_percent(1);

	1;
}

sub command {
	my $self = shift;

	my $title  = $self->title;
	
	my $command = $title->get_probe_command;
	
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
	
	$self->title->analyze_probe_output (
		output => $self->pipe->output
	);

	$self->title->suggest_transcode_options;

	$self->log ("Successfully probed title #".$self->title->nr);
	
	1;
}

1;
