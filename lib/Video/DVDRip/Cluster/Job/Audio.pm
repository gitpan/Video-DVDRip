# $Id: Audio.pm,v 1.1 2002/02/11 17:09:48 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::Audio;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub psu				{ shift->{psu}				}
sub chunk_cnt			{ shift->{chunk_cnt}			}
sub move_final			{ shift->{move_final}			}

sub set_psu			{ shift->{psu}			= $_[1]	}
sub set_chunk_cnt		{ shift->{chunk_cnt}		= $_[1]	}
sub set_move_final		{ shift->{move_final}		= $_[1]	}

sub type {
	return "audio processing";
}

sub info {
	my $self = shift;

	return "process audio of psu ".$self->psu;
}

sub start {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get audio processing command
	$project->set_assigned_job ( $self );
	my $command = $title->get_process_audio_command;
	$project->set_assigned_job ( undef );
	
	$self->set_progress_frames( 0 );

	my $successful_finished = 0;
	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /split.*?frames\s+(\d+)-(\d+)/ ) {
				$self->set_progress_frames_cnt ($2-$1);
			} elsif ( $line =~ /encoding.*?\[(\d{6})-(\d+)\]/ ) {
				$self->set_progress_frames($2-$1);
			} elsif ( $line =~ /DVDRIP_SUCCESS/ ) {
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

1;
