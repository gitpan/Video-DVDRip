# $Id: TranscodeVideo.pm,v 1.5 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::TranscodeVideo;

use base Video::DVDRip::Job::TranscodeVideo;

use Carp;
use strict;

sub pass			{ shift->{pass}				}
sub psu				{ shift->{psu}				}
sub chunk			{ shift->{chunk}			}
sub chunk_cnt			{ shift->{chunk_cnt}			}

sub set_pass			{ shift->{pass}			= $_[1]	}
sub set_psu			{ shift->{psu}			= $_[1]	}
sub set_chunk			{ shift->{chunk}		= $_[1]	}
sub set_chunk_cnt		{ shift->{chunk_cnt}		= $_[1]	}

sub type {
	return "transcode";
}

sub info {
	my $self = shift; $self->trace_in;

	return  "transcode video".
		" chunk ".$self->chunk."/".$self->chunk_cnt.
		", pass ".$self->pass.
		", psu ".$self->psu;
}

sub init {
	my $self = shift; $self->trace_in;
	 
	$self->project->set_assigned_job ( $self );
	$self->SUPER::init;
	$self->project->set_assigned_job ( undef );
	 
	$self->set_progress_max ($self->title->frames_per_chunk);
	
	1;
}

sub command {
	my $self = shift; $self->trace_in;

	my $project = $self->project;
	my $title   = $project->title;

	# get transcode command
	$project->set_assigned_job ( $self );
	my $command = $title->get_transcode_command ( pass => $self->pass );
	$project->set_assigned_job ( undef );

	return $command;
}

sub commit {
	my $self = shift; $self->trace_in;

	my $node     = $self->node;
	my $project  = $self->project;
	my $title    = $project->title;
	my $chunk    = $self->chunk;

	$title->set_frames_finished (
		$title->frames_finished +
		$self->progress_max
	);

	1;
}

1;
