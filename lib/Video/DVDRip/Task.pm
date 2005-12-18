# $Id: Task.pm,v 1.1 2005/10/09 12:04:25 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Task;

use base qw( Video::DVDRip::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub ui				{ shift->{ui}				}
sub project			{ shift->{project}			}
sub reuse_progress		{ shift->{reuse_progress}		}
sub no_diskspace_check		{ shift->{no_diskspace_check}		}
sub max_diskspace_needed	{ shift->{max_diskspace_needed}		}
sub cancelled			{ shift->{cancelled}			}
sub cancelled_job		{ shift->{cancelled_job}		}
sub errors_occured		{ shift->{errors_occured}		}
sub cb_finished			{ shift->{cb_finished}			}
sub jobs			{ shift->{jobs}				}
sub configure_failed		{ shift->{configure_failed}		}
sub next_task			{ shift->{next_task}			}
sub cb_error			{ shift->{cb_error}			}

sub set_ui			{ shift->{ui}			= $_[1]	}
sub set_project			{ shift->{project}		= $_[1]	}
sub set_reuse_progress		{ shift->{reuse_progress}	= $_[1]	}
sub set_no_diskspace_check	{ shift->{no_diskspace_check}	= $_[1]	}
sub set_max_diskspace_needed	{ shift->{max_diskspace_needed}	= $_[1]	}
sub set_cancelled		{ shift->{cancelled}		= $_[1]	}
sub set_cancelled_job		{ shift->{cancelled_job}	= $_[1]	}
sub set_errors_occured		{ shift->{errors_occured}	= $_[1]	}
sub set_cb_finished		{ shift->{cb_finished}		= $_[1]	}
sub set_jobs			{ shift->{jobs}			= $_[1]	}
sub set_configure_failed	{ shift->{configure_failed}	= $_[1]	}
sub set_next_task		{ shift->{next_task}		= $_[1]	}
sub set_cb_error		{ shift->{cb_error}		= $_[1]	}

sub configure			{ die "$_[0] has no configure()"	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($ui, $reuse_progress, $project, $cb_finished) =
	@par{'ui','reuse_progress','project','cb_finished'};
	my  ($no_diskspace_check, $max_diskspace_needed) =
	@par{'no_diskspace_check','max_diskspace_needed'};
	my  ($cb_error) =
	@par{'cb_error'};

	my $self = bless {
		ui			=> $ui,
		reuse_progress		=> $reuse_progress,
		project			=> $project,
		no_diskspace_check	=> $no_diskspace_check,
		max_diskspace_needed	=> $max_diskspace_needed,
		cb_finished		=> $cb_finished,
		cb_error		=> $cb_error,
		jobs			=> [],
	}, $class;

	return $self;
}

sub add_job {
	my $self = shift;
	my ($job) = @_;

	my $nr = $self->jobs->[-1] ? $self->jobs->[-1]->nr + 1 : 1;
	$job->set_nr($nr);
	$job->set_task($self);

	push @{$self->jobs}, $job;
	
	return $job;
}

sub calc_max_disk_usage {
	my $self = shift;

	my $jobs = $self->jobs;

	my $current_disk_usage = 0;
	my $max_disk_usage     = 0;
	
	foreach my $job ( @{$jobs} ) {
		$current_disk_usage += $job->get_diskspace_needed
			if $job->can('get_diskspace_needed');
		
		$max_disk_usage = $current_disk_usage
			if $current_disk_usage > $max_disk_usage; 
		$current_disk_usage -= $job->get_diskspace_freed
			if $job->can('get_diskspace_freed');
	}
	
	return $max_disk_usage;
}

sub start {
	my $self = shift;

	return if $self->configure_failed;

	my $jobs		 = $self->jobs;
	my $project		 = $self->project;
	my $title   		 = $project->content->selected_title;
	my $no_diskspace_check   = $self->no_diskspace_check;
	my $max_diskspace_needed = $self->max_diskspace_needed;

	my $job_started;

	if ( $title and not $no_diskspace_check ) {
		$max_diskspace_needed ||= $self->calc_max_disk_usage;

		my $free = $project->get_free_diskspace ( kb => 1 );

		$max_diskspace_needed = int ($max_diskspace_needed/1024);
		$free = int($free/1024);

		$self->log (
		    __x("This task needs about {needed} MB, {free} MB are free.",
		        needed => $max_diskspace_needed, free => $free)
		);

		my $max_diskspace_needed_plus_spare = $max_diskspace_needed + 100;
		if ( $max_diskspace_needed_plus_spare > $free ) {
			$self->ui->confirm_window (
			    message =>
				__x("Warning: diskspace is low. This task needs\n".
				    "about {needed} MB, but only {free} MB are available.\n".
				    "Do you want to continue anyway?",
				    needed => $max_diskspace_needed_plus_spare, free => $free
				),
			    yes_callback => sub {
			        $self->set_no_diskspace_check(1);
			    	$self->start;
			    },
			    yes_label   => __"Yes",
			    no_label    => __"No",
			    no_callback => sub {
			    	$self->set_cancelled(1);
				$self->finished;
			    },
			    omit_cancel => 1,
			);
			return 1;
		}
	}

	my $progress = $self->ui->progress;

	foreach my $job ( @{$jobs} ) {
#print "job=".$job->info."\n";
#print "state=".$job->state."\n";
#print "dependency_ok=".$job->dependency_ok."\n";
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

		if ( not $progress->is_active ) {
			$progress->open (
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
			$self->ui->long_message_window (
				message => $@,
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
		$self->ui->long_message_window (
			message => $last_job->error_message
		);
	}

	$self->ui->progress->close
		unless $self->reuse_progress;
	
	$self->start ( no_diskspace_check => 1 );
	
	1;
}

sub job_aborted {
	my $self = shift;
	my %par = @_;
	my ($job) = @par{'job'};

	$self->set_errors_occured(1);

	$self->ui->progress->close
		unless $self->reuse_progress;

	if ( $job->cancelled ) {
		$self->set_cancelled(1);
		$self->finished;
		return 1;
	}

	if ( $job->error_message ) {
		$self->ui->long_message_window (
		    message => $job->error_message
		);
	} else {
		$self->ui->long_message_window (
		    message =>
		    __x(
		        "Job '{job}' failed.\n\nExecuted command: {command}\n\n".
		        "Last output was:\n\n",
			job => $job->info,
			command => $job->command 
		    ).
		    $job->pipe->output
		);
		$self->log (
			__"You should analyze the last output of this ".
			  "job to see what's going wrong here:"
		);
		my $output = $job->pipe->output;
		$output =~ s/^DVDRIP_JOB_PID=\d+$//mg;
		$output =~ s/^\s+//;
		$output =~ s/\s+$//;
		$self->log (__"---- job output start ----")."\n\n\n";
		$self->log ($output);
		$self->log (__"---- job output end ----");
	}

	my $cb_error = $self->cb_error;
	&$cb_error() if $cb_error;

	1;
}

sub finished {
	my $self = shift;

	my $progress = $self->ui->progress;
	$progress->close if $progress->is_active;

	my $cb_finished = $self->cb_finished;
	&$cb_finished() if $cb_finished;

	my $errors_occured = $self->errors_occured;
	my $next_task      = $self->next_task;
	my $cb_error       = $self->cb_error;

	if ( $errors_occured && $cb_error ) {
		&$cb_error();
		return;
	}

	if ( !$errors_occured and $next_task ) {
		$next_task->configure;
		$next_task->start;
	}
	
	1;
}

sub update_progress {
	my $self = shift;
	my %par = @_;
	my ($job) = @par{'job'};

	return 1 if $self->cancelled;
	
	my $max = $job->progress_max;
	my $cnt = $job->progress_cnt;
	$max ||= 1;
	
	$self->ui->progress->update (
		value => $cnt/$max,
		label => $job->progress,
	);
	
	1;
}

1;

