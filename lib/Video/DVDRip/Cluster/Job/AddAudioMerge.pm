# $Id: AddAudioMerge.pm,v 1.3 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::AddAudioMerge;

use base Video::DVDRip::Job::MergeAudio;

use Carp;
use strict;

sub psu				{ shift->{psu}				}
sub move_final			{ shift->{move_final}			}

sub set_psu			{ shift->{psu}			= $_[1]	}
sub set_move_final		{ shift->{move_final}		= $_[1]	}

sub type {
	return "merge audio";
}

sub info {
	my $self = shift;

	my $info = "add audio, track #".
		   $self->vob_nr.
		   ", psu ".$self->psu;
	
	return $info;
}

sub init {
	my $self = shift;
	 
	$self->SUPER::init;
	 
	$self->set_progress_max (
		$self->title
		     ->program_stream_units
		     ->[$self->psu]
		     ->frames
	);
	
	1;
}

sub command {
	my $self = shift;

	my $project = $self->project;
	my $title   = $self->title;

	$title->set_actual_chapter ($self->chapter);
	$project->set_assigned_job ( $self );

	my $command = $title->get_merge_audio_command (
		vob_nr    => $self->vob_nr,
		target_nr => $self->avi_nr,
	);

	$project->set_assigned_job ( undef );
	$title->set_actual_chapter (undef);

	return $command;
}

1;
