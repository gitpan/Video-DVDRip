# $Id: MergeChunks.pm,v 1.5 2002/03/17 18:52:39 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergeChunks;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub psu				{ shift->{psu}				}
sub set_psu			{ shift->{psu}			= $_[1]	}

sub chunk_cnt			{ shift->{chunk_cnt}			}
sub set_chunk_cnt		{ shift->{chunk_cnt}		= $_[1]	}

sub progress_chunks		{ shift->{progress_chunks}	= $_[1]	}
sub set_progress_chunks		{ shift->{progress_chunks}	= $_[1]	}

sub move_final			{ shift->{move_final}			}
sub set_move_final		{ shift->{move_final}		= $_[1]	}

sub type {
	return "psu merge";
}

sub info {
	my $self = shift;

	return "merge video chunks";
}

sub start {
	my $self = shift;

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_chunks_command;
	$project->set_assigned_job ( undef );

	$self->set_progress_chunks(1);

	my $successful_finished = 0;
	$self->popen (
		command      => $command,
		cb_line_read => sub {
			my ($line) = @_;
			if ( $line =~ /DVDRIP_SUCCESS/ ) {
				$successful_finished = 1;

			} elsif ( $line =~ /file\s+(\d+)\s+/ ) {
				$self->set_progress_chunks($1);
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

       return "Runtime: ".$self->progress_runtime;
}
 
1;
