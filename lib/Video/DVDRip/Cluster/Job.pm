# $Id: Job.pm,v 1.16 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Job;

use base Video::DVDRip::Job;

use Video::DVDRip::Cluster::Pipe;

use Carp;
use strict;

sub id				{ shift->{id}				}

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1]	}

sub prefer_local_access		{ shift->{prefer_local_access}		}
sub set_prefer_local_access	{ shift->{prefer_local_access}	= $_[1]	}

sub node			{ shift->{node}				}
sub set_node			{ shift->{node}			= $_[1]	}

sub title {
	shift->project->title;
}

sub progress_info { "" }

sub new {
	my $class = shift;
	my %par = @_;
	my ($nr) = @par{'nr'};

	my $self = $class->SUPER::new(@_);
	$self->{id} = Video::DVDRip::Cluster::Master->get_master
					            ->get_next_job_id;

	$self->set_state ("not scheduled");
	$self->set_pipe_class ("Video::DVDRip::Cluster::Pipe");
	$self->set_progress_show_elapsed ( 0 );

	return $self;
}

sub log {
	my $self = shift; $self->trace_in;
	my ($msg) = @_;

	$msg =~ s/\n$//;
	$msg .= " on node ".$self->node->name;
	
	return $self->SUPER::log ($msg);
}

sub start_job {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($node) = @par{'node'};

	$self->set_node ($node);
	$node->set_assigned_job ($self);
	$node->set_state ('running');

	$self->SUPER::start_job();

	$self->project->set_state ('running');
	$self->project->save;

	1;
}

sub get_job_command {
	my $self = shift; $self->trace_in;
	
	return $self->node->get_popen_code ( command => $self->command );
}

sub commit_job {
	my $self = shift; $self->trace_in;
	
	$self->SUPER::commit_job;

	$self->project->determine_state;

	$self->node->set_state ('idle');
	$self->node->set_assigned_job (undef);
	$self->set_node(undef);

	$self->project->save;

	Video::DVDRip::Cluster::Master->get_master->job_control;

	1;
}

sub abort_job {
	my $self = shift; $self->trace_in;
	
	my $pipe = $self->pipe; # save pipe (set to undef in SUPER method)

	$self->SUPER::abort_job();
	
	if ( $self->node->state ne 'stopped' ) {
		# this was an unexpected abort, so log
		# the command output and set the node state
		# to 'aborted'
		$self->log (
			"Last output of job was:\n".
			$pipe->output_tail
		);
		$self->set_state ('aborted');
	} else {
		$self->set_state ('waiting');
	}

	$self->node->set_assigned_job (undef);
	$self->set_node(undef);

	$self->project->determine_state;
	$self->project->save;

	Video::DVDRip::Cluster::Master->get_master->job_control;

	1;
}

1;
