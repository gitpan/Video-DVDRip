# $Id: Transcode.pm,v 1.4 2002/03/02 16:18:38 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::Transcode;

use base Video::DVDRip::Cluster::Job;

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
	my $self = shift;

	return  "transcode".
		" chunk ".$self->chunk."/".$self->chunk_cnt.
		", pass ".$self->pass.
		", psu ".$self->psu;
}

sub start {
	my $self = shift;

	my $project = $self->project;
	my $title   = $project->title;

	# get transcode command
	$project->set_assigned_job ( $self );
	my $command = $title->get_transcode_command ( pass => $self->pass );
	$project->set_assigned_job ( undef );

	# start command
	my $frames_cnt;
	my $successful_finished = 0;

	$self->set_progress_frames (0);

	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /split.*?frames.*?-c\s+\d+-(\d+)/ ) {
				$self->set_progress_frames_cnt ($1);
				$frames_cnt = $1;

			} elsif ( $line =~ /\[\d{6}-(\d+)\]/ ) {
				$self->set_progress_frames($1);

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

sub commit {
	my $self = shift;

	my $node     = $self->node;
	my $project  = $self->project;
	my $title    = $project->title;
	my $chunk    = $self->chunk;

	$title->set_frames_finished (
		$title->frames_finished +
		$self->progress_frames_cnt
	);

	# move chunk file to its final destination,
	# if we finished pass 2 or doesn't use
	# multipass encoding
	if ( $self->pass == 2 or not $title->tc_multipass ) {
		$project->set_assigned_job ( $self );
		my $command = $title->get_move_avi_command;
		$command = $self->node->get_popen_code ( command => $command );
		$project->set_assigned_job ( undef );
	
		$self->log ("Moving avi file to its final destination: $command");
		qx($command);
	}

	# job is finished
	$self->set_state ('finished');

	1;
}

1;
