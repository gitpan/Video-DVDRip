# $Id: ExtractPS1.pm,v 1.3.2.1 2003/02/15 09:39:05 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::ExtractPS1;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub subtitle			{ shift->{subtitle}			}
sub set_subtitle		{ shift->{subtitle}		= $_[1]	}

sub type {
	return "extract ps1";
}

sub info {
	my $self = shift;

	my $sid = $self->subtitle->id;

	my $info = "Extract subtitle #$sid from title #".$self->title->nr;
	
	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$self->set_progress_show_fps ( 0 );

	if ( $title->project->rip_mode eq 'rip' ) {
		$self->set_progress_max ( 10000 );
	} else {
		$self->set_progress_show_percent ( 0 );
	}

	1;
}

sub command {
	my $self = shift;

	my $ps1_file = $self->subtitle->ps1_file;

	if ( -f $ps1_file ) {
		$self->log (
			"PS1 file '$ps1_file' already exists. ".
			"Skip extraction."
		);

		$self->set_progress_cnt (10000);

		return "echo DVDRIP_SUCCESS";
	}

	return $self->title->get_extract_ps1_stream_command (
		subtitle => $self->subtitle
	);
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ($line =~ /dr_progress/ ) {
		$line =~ m!(\d+)/(\d+)\n.*?$!;
		$self->set_progress_cnt (10000*$1/$2);
	}

	$self->set_operation_successful (1)
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

sub rollback {
	my $self = shift;

	unlink $self->subtitle->ps1_file;
	
	1;
}

1;
