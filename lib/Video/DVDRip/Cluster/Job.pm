# $Id: Job.pm,v 1.10 2002/02/18 23:02:49 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job;

use base Video::DVDRip::Base;

use Video::DVDRip::Cluster::Pipe;

use Carp;
use strict;

sub id				{ shift->{id}				}
sub nr				{ shift->{nr}				}

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1]	}

sub prefer_local_access		{ shift->{prefer_local_access}		}
sub set_prefer_local_access	{ shift->{prefer_local_access}	= $_[1]	}

sub depends_on_jobs		{ shift->{depends_on_jobs}		}
sub set_depends_on_jobs		{ shift->{depends_on_jobs}	= $_[1]	}

sub dep_as_string		{ shift->{dep_as_string}		}
sub set_dep_as_string		{ shift->{dep_as_string}	= $_[1]	}

sub state			{ shift->{state}			}
sub set_state			{ shift->{state}		= $_[1]	}

sub node			{ shift->{node}				}
sub set_node			{ shift->{node}			= $_[1]	}

sub pipe			{ shift->{pipe}				}
sub set_pipe			{ shift->{pipe}			= $_[1]	}

sub progress_start_time		{ shift->{progress_start_time}		}
sub set_progress_start_time	{ shift->{progress_start_time}	= $_[1]	}

sub progress_end_time		{ shift->{progress_end_time}		}
sub set_progress_end_time	{ shift->{progress_end_time}	= $_[1]	}

sub progress_frames		{ shift->{progress_frames}		}
sub set_progress_frames		{ shift->{progress_frames}	= $_[1]	}

sub progress_frames_cnt		{ shift->{progress_frames_cnt}		}
sub set_progress_frames_cnt	{ shift->{progress_frames_cnt}	= $_[1]	}

sub duration			{ shift->{duration}			}
sub set_duration		{ shift->{duration}		= $_[1]	}


sub new {
	my $class = shift;
	my %par = @_;
	my ($nr) = @par{'nr'};

	my $id = Video::DVDRip::Cluster::Master->get_master
					       ->get_next_job_id;

	my $self = bless {
		id			=> $id,
		depends_on_jobs 	=> [],
		state   	   	=> 'not scheduled',
		nr			=> $nr,
	}, $class;
	
	return $self;
}

sub start_job {
	my $self = shift;
	my %par = @_;
	my ($node) = @par{'node'};

	my $id = $self->id;

	$self->log (
		"Starting job ($id): ".$self->info." on node ".$node->name
	);

	$self->set_state ("running");
	$self->project->set_state ('running');

	$self->set_node ($node);
	$node->set_assigned_job ($self);
	$node->set_state ('running');

	$self->set_progress_start_time ( time );
	$self->start;

	$self->project->save;

	1;
}

sub commit_job {
	my $self = shift;
	
	my $id = $self->id;

	$self->log (
		"Successfully finished job ($id): ".$self->info.
		" on node ".$self->node->name
	);
	
	$self->commit if $self->can ('commit');

	$self->set_progress_end_time (time);

	$self->set_duration (
		$self->format_time (
			time => $self->progress_end_time -
				$self->progress_start_time
		)
	);

	$self->set_state ("finished");
	$self->set_pipe (undef);

	$self->project->determine_state;

	$self->node->set_state ('idle');
	$self->node->set_assigned_job (undef);
	$self->set_node(undef);

	$self->project->save;

	Video::DVDRip::Cluster::Master->get_master->job_control;

	1;
}

sub abort_job {
	my $self = shift;
	
	my $node = $self->node;

	$self->log (
		"Aborting job: ".$self->info.
		" on node ".$self->node->name
	);
	
	$self->abort if $self->can ('abort');

	if ( $node->state ne 'stopped' ) {
		# this was an unexpected abort, so log
		# the command output and set the node state
		# to 'aborted'
		$self->log (
			"Last output of job was:\n".
			$self->pipe->output_tail
		);
		$node->set_state ('aborted');
		$node->save;
	}

	$node->set_assigned_job (undef);
	$self->set_node(undef);

	$self->set_state ("aborted");
	$self->set_pipe (undef);
	$self->project->determine_state;
	$self->project->save;

	Video::DVDRip::Cluster::Master->get_master->job_control;

	1;
}


sub progress {
	my $self = shift;
	
	my $state = $self->state;
	return $self->calc_progress if $state eq 'running';	

	return "" if $state eq 'waiting' or
		     $state eq 'aborted';

	return "" if not $self->duration;
	return "Duration ".$self->duration;
}
	

sub calc_progress {
	my $self = shift;

	my $frames     = $self->progress_frames;
	my $frames_cnt = $self->progress_frames_cnt || 1;
	my $time       = (time - $self->progress_start_time);
	my $fps	       = 0;
	
	$fps = sprintf ("%2.1f", $frames / $time) if $time;
	
	my $eta;

	$eta = ", ETA: ".$self->format_time (
		time => int ( $time * $frames_cnt / $frames ) - $time
	) if $frames > 50;

	return sprintf (
		"%2.2f\%, %2.1f fps%s",
		$frames / $frames_cnt * 100,
		$fps,
		$eta
	);
}

sub progress_runtime {
	my $self = shift;

	return $self->format_time ( time => time - $self->progress_start_time);
}

sub popen {
	my $self = shift;
	my %par = @_;
	my  ($command, $cb_line_read, $cb_finished, $timeout) =
	@par{'command','cb_line_read','cb_finished','timeout'};

	$command = $self->node->get_popen_code ( command => $command );

	$self->log (3, "Executing command: $command");

	my $pipe = Video::DVDRip::Cluster::Pipe->new (
		command => $command,
		cb_line_read => $cb_line_read,
		cb_finished  => $cb_finished,
		timeout => $timeout,
	);

	$self->set_pipe ( $pipe );
	
	1;
}

sub stop {
	my $self = shift;

	$self->pipe->abort;

	1;
}

sub calc_dep_string {
	my $self = shift;
	
	$self->set_dep_as_string("none"), return if not @{$self->depends_on_jobs};
	
	# get numbers
	my @nr = map { $_->nr } @{$self->depends_on_jobs};
	push @nr, 99999;	# eof

	my $dep_str;
	my $first_nr = shift @nr;
	my $last_nr  = $first_nr;

	foreach my $nr ( @nr ) {
		$first_nr ||= $nr;
		if ( $nr > $last_nr + 1 ) {
			$dep_str .= "$first_nr-$last_nr," if $first_nr < $last_nr;
			$dep_str .= "$first_nr," if $first_nr == $last_nr;
			$dep_str .= "$last_nr," if $first_nr > $last_nr;
			$first_nr = undef;
		}
		$last_nr = $nr;
	}

	$dep_str =~ s/.99999,$//;
	$dep_str =~ s/,$//;

	$self->set_dep_as_string ( $dep_str );

	1;
}

sub dependency_ok {
	my $self = shift;
	
	foreach my $job ( @{$self->depends_on_jobs} ) {
		return if not $job->state eq 'finished';
	}
	
	return 1;
}

1;
