# $Id: ExecuteJobs.pm,v 1.13.2.1 2003/03/03 11:37:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
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
use Video::DVDRip::Job::CreateCDImage;
use Video::DVDRip::Job::BurnCD;
use Video::DVDRip::Job::GrabSubtitleImages;
use Video::DVDRip::Job::ExtractPS1;
use Video::DVDRip::Job::CreateVobsub;
use Video::DVDRip::Job::CountFramesInFile;
use Video::DVDRip::Job::CreateWav;

use strict;
use Carp;

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
	my %par = @_;
	my  ($no_diskspace_check, $max_diskspace_needed) =
	@par{'no_diskspace_check','max_diskspace_needed'};

	my $jobs = $self->jobs;

	my $job_started;
	my $title = $self->comp('project')->selected_title;

	if ( $title and not $no_diskspace_check ) {
		$max_diskspace_needed ||=
			Video::DVDRip::Job->get_max_disk_usage (
				jobs => $jobs,
			);

		my $free = $title->project->get_free_diskspace ( kb => 1 );

		$max_diskspace_needed = int ($max_diskspace_needed/1024);
		$free = int($free/1024);

		$self->log ("This task needs about $max_diskspace_needed MB, $free MB are free.");

		if ( $max_diskspace_needed + 100 > $free ) {
			$self->confirm_window (
			    message =>
				"Warning: diskspace is low. This task needs\n".
				"about $max_diskspace_needed MB, but only $free MB are available.\n".
				"Do you want to continue anyway?",
			    yes_callback => sub {
			    	$self->execute_jobs (
				    no_diskspace_check => 1,
				);
			    },
			    yes_label => "Yes",
			    no_label => "No",
			    no_callback => sub {
			    	$self->set_cancelled(1);
				$self->finished;
			    },
			    omit_cancel => 1,
			);
			return 1;
		}
	}

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
	
	$self->execute_jobs ( no_diskspace_check => 1);
	
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
		$self->log (
			"You should analyze the last output of ".
			"this job to see what's going wrong here:"
		);
		my $output = $job->pipe->output;
		$output =~ s/^\s+//;
		$output =~ s/\s+$//;
		$self->log ("---- job output start ----\n\n".$output."\n");
		$self->log ("---- job output end ----");
	}

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
