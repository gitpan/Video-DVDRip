# $Id: MergeAudio.pm,v 1.1 2002/03/12 14:03:42 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergeAudio;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub psu				{ shift->{psu}				}
sub move_final			{ shift->{move_final}			}

sub set_psu			{ shift->{psu}			= $_[1]	}
sub set_move_final		{ shift->{move_final}		= $_[1]	}

sub type {
	return "audio merge";
}

sub info {
	my $self = shift;

	return "merge audio of psu ".$self->psu;
}

sub start {
	my $self = shift;

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_audio_command;
	$project->set_assigned_job ( undef );

	my $successful_finished = 0;
	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /DVDRIP_SUCCESS/ ) {
				$successful_finished = 1;
			}
		},
		cb_finished  => sub {
			if ( $successful_finished ) {
				$self->commit_job;
			} else {
				$self->abort_job;
			}
		},
	);

	1;
}

sub calc_progress {
	my $self = shift;

       return "Merging audio of PSU ".$self->psu.", ".
	      $self->progress_runtime;
}
 
1;
