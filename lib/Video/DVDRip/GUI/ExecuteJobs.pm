# $Id: ExecuteJobs.pm,v 1.3 2002/09/22 09:36:07 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::ExecuteJobs;


use base Video::DVDRip::GUI::Base;

use Video::DVDRip::GUI::Pipe;

use Video::DVDRip::Job::Probe;
use Video::DVDRip::Job::Rip;
use Video::DVDRip::Job::GrabPreviewFrame;
use Video::DVDRip::Job::ScanVolume;
use Video::DVDRip::Job::TranscodeVideo;
use Video::DVDRip::Job::Split;
use Video::DVDRip::Job::Mplex;
use Video::DVDRip::Job::TranscodeAudio;
use Video::DVDRip::Job::MergeAudio;

use strict;

# list ref of jobs, to bew executed in the specified order
sub jobs			{ shift->{jobs}				}
sub set_jobs			{ shift->{jobs}			= $_[1]	}

# set to true, if all jobs has the same max_value and the
# progress bar should be reused
sub reuse_progress		{ shift->{reuse_progress}		}
sub set_reuse_progress		{ shift->{reuse_progress}	= $_[1]	}

# *allways* called after overall job execution
# (even when jobs are aborted or the user cancelled operation)
sub cb_finished			{ shift->{cb_finished}			}
sub set_cb_finished		{ shift->{cb_finished}		= $_[1]	}

# true, if user cancelled job execution
sub cancelled			{ shift->{cancelled}			}
sub set_cancelled		{ shift->{cancelled}		= $_[1]	}

# job, which was cancelled
sub cancelled_job		{ shift->{cancelled_job}		}
sub set_cancelled_job		{ shift->{cancelled_job}	= $_[1]	}

# true, if minimum one job aborted with error
sub errors_occured		{ shift->{errors_occured}		}
sub set_errors_occured		{ shift->{errors_occured}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($cb_finished, $reuse_progress) =
	@par{'cb_finished','reuse_progress'};

	my $self = {
		jobs		=> [],
		cb_finished 	=> $cb_finished,
		reuse_progress	=> $reuse_progress,
	};
	
	return bless $self, $class;
}

sub add_job {
	my $self = shift;
	my %par = @_;
	my ($job) = @par{'job'};

	push @{$self->jobs}, $job;
	
	return $job;
}

sub execute_jobs {
	my $self = shift;
	
	my $jobs = $self->jobs;

	my $job_started;

	foreach my $job ( @{$jobs} ) {
		next if $job->state ne 'waiting';
		next if not $job->dependency_ok;
		
		$job_started = 1;
		$job->init if $job->can('init');
		$job->set_cb_next_job (
			sub { $self->next_job ( last_job => $_[0] ) } 
		);
		$job->set_cb_job_aborted (
			sub { $self->job_aborted ( job => $job ) } 
		);
		$job->set_cb_update_progress (
			sub { $self->update_progress(@_) }
		);

		if ( not $self->comp('progress')->is_active ) {
			$self->comp('progress')->open (
				max_value => $job->progress_max,
				label     => $job->calc_progress,
				cb_cancel => sub {
					$self->set_cancelled(1);
					$self->set_cancelled_job ($job);
					$job->cancel;
					1;
				},
			);
		}

		eval { $job->start_job };

		if ( $@ ) {
			$self->long_message_window (
				message => $self->stripped_exception
			);
			$job_started = 0;
			next;
		}

		last;
	}
	
	
	if ( not $job_started ) {
		$self->finished;
	}

	1;
}

sub next_job {
	my $self = shift;
	my %par = @_;
	my ($last_job) = @par{'last_job'};

	return $self->finished if $self->cancelled;

	if ( $last_job->error_message ) {
		$self->set_errors_occured(1);
		$self->long_message_window (
			message => $last_job->error_message
		);
	}

	$self->comp('progress')->close
		if not $self->reuse_progress;
	
	$self->execute_jobs;
	
	1;
}

sub finished {
	my $self = shift;

	$self->comp('progress')->close
		if $self->comp('progress')->is_active;

	my $cb_finished = $self->cb_finished;
	&$cb_finished() if $cb_finished;

	1;
}

sub job_aborted {
	my $self = shift;
	my %par = @_;
	my ($job) = @par{'job'};

	$self->set_errors_occured(1);

	$self->comp('progress')->close
		if not $self->reuse_progress;

	if ( $job->cancelled ) {
		$self->set_cancelled(1);
		$self->finished;
		return 1;
	}

	if ( $job->error_message ) {
		$self->long_message_window ( message => $job->error_message );
	} else {
		$self->long_message_window (
			message =>
				"Job '".$job->info."' failed.\n\n".
				"Executed command: ".$job->command."\n\n".
				"Last output was:\n\n".
				$job->pipe->output
		);
	}
	# try hard
	$self->execute_jobs;

	1;
}

sub update_progress {
	my $self = shift;
	my %par = @_;
	my ($job) = @par{'job'};

	return 1 if $self->cancelled;

	$self->comp('progress')->update (
		value => $job->progress_cnt,
		label => $job->progress,
	);
	
	1;
}

1;
