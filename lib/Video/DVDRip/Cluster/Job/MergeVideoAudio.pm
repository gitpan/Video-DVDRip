# $Id: MergeVideoAudio.pm,v 1.7 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergeVideoAudio;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Job::MergeAudio;

use Carp;
use strict;

sub psu				{ shift->{psu}				}
sub set_psu			{ shift->{psu}			= $_[1]	}

sub move_final			{ shift->{move_final}			}
sub set_move_final		{ shift->{move_final}		= $_[1]	}

sub type {
	return "multiplex video and audio";
}

sub info {
	my $self = shift;

	return "merge video chunks psu ".$self->psu if $self->title->is_ogg;
	return "multiplex video and audio psu ".$self->psu;
}

sub init {
	my $self = shift;
	 
	my $project  = $self->project;
	$project->set_assigned_job ( $self );
	$self->SUPER::init;
	$project->set_assigned_job ( undef );
	 
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

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_video_audio_command;
	$project->set_assigned_job ( undef );

	return $command;
}

1;
