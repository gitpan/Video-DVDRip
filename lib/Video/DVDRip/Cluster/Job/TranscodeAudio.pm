# $Id: TranscodeAudio.pm,v 1.8 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::TranscodeAudio;

use base Video::DVDRip::Job::TranscodeAudio;

use Carp;
use strict;

sub psu				{ shift->{psu}				}
sub chunk_cnt			{ shift->{chunk_cnt}			}

sub set_psu			{ shift->{psu}			= $_[1]	}
sub set_chunk_cnt		{ shift->{chunk_cnt}		= $_[1]	}

sub info {
	my $self = shift; $self->trace_in;

	return  "transcode audio track #".
		$self->vob_nr.", psu ".$self->psu;
}

sub init {
	my $self = shift; $self->trace_in;
	 
	$self->project->set_assigned_job ( $self );
	$self->SUPER::init;
	$self->project->set_assigned_job ( undef );
	 
	$self->set_progress_max (
		$self->title
		     ->program_stream_units
		     ->[$self->psu]
		     ->frames
	);
	
	1;
}

sub command {
	my $self = shift; $self->trace_in;

	my $project = $self->project;
	my $title   = $project->title;

	# get transcode command
	$project->set_assigned_job ( $self );
	my $command = $title->get_transcode_audio_command (
		vob_nr    => $self->vob_nr,
		target_nr => $self->avi_nr,
	);
	$project->set_assigned_job ( undef );

	return $command;
}

sub commit {
	my $self = shift;

	$self->project->set_assigned_job ( $self );

	if ( $self->bc ) {
		$self->bc->add_audio_size (
			bytes => -s $self->project->title->target_avi_audio_file (
				vob_nr => $self->vob_nr,
				avi_nr => $self->avi_nr,
			)
		);
	}

	$self->project->set_assigned_job ( undef );
	
	1;
}

1;
