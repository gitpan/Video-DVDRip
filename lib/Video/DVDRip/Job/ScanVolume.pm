# $Id: ScanVolume.pm,v 1.1 2002/09/01 13:57:52 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::ScanVolume;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub type {
	return "scan";
}

sub info {
	my $self = shift;

	my $info = "Volume scanning - title #".$self->title->nr;
	$info .= ", audio track #".$self->title->audio_channel;

	return $info;
}

sub init {
	my $self = shift;
	
	my $title    = $self->title;
	
	if ( $title->project->rip_mode eq 'rip' ) {
		$self->set_progress_show_fps ( 0 );
		$self->set_progress_max ( $title->get_vob_size );
	} else {
		$self->set_progress_show_fps ( 1 );
		$self->set_progress_max ( $title->frames );
	}
	
	1;
}

sub command {
	my $self = shift;

	return $self->title->get_scan_command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ($line =~ /dr_progress/ ) {
		$line =~ m!(\d+)/\d+\n.*?$!;
		$self->set_progress_cnt ($1);
	} else {
		my $frames = $self->progress_cnt;
		++$frames while $line =~ /^[\d\t ]+$/gm;
		$self->set_progress_cnt ($frames);
	}

	$self->set_operation_successful (1)
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift;
	
	$self->title->analyze_scan_output (
		output => $self->pipe->output
	);
	
	1;
}

1;
