# $Id: MergePSUs.pm,v 1.3 2002/02/18 23:03:34 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job::MergePSUs;

use base Video::DVDRip::Cluster::Job;

use Carp;
use strict;

sub chunk_cnt			{ shift->{chunk_cnt}			}
sub set_chunk_cnt		{ shift->{chunk_cnt}		= $_[1]	}

sub progress_chunks		{ shift->{progress_chunks}		}
sub set_progress_chunks		{ shift->{progress_chunks}	= $_[1]	}

sub type {
	return "psu merge";
}

sub info {
	my $self = shift;

	return "merge program stream units";
}

sub start {
	my $self = shift;

	my $project  = $self->project;
	my $title    = $project->title;

	# get merge command
	$project->set_assigned_job ( $self );
	my $command = $title->get_merge_psu_command;
	$project->set_assigned_job ( undef );

	$self->set_progress_chunks(1);

	my $successful_finished = 0;
	$self->popen (
		timeout      => -1,
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

	return 	"Chunk ".($self->progress_chunks||1)."/".$self->chunk_cnt.
		", ".$self->progress_runtime;
}
 
1;
