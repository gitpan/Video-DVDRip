# $Id: Master.pm,v 1.33 2005/05/16 08:03:45 joern Exp $
#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Master;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Event;
use constant NICE => -1;

use Video::DVDRip::Cluster::Job;
use Video::DVDRip::Cluster::Node;
use Video::DVDRip::Cluster::Project;
use Video::DVDRip::Cluster::Pipe;

use Carp;
use strict;

use FileHandle;
use Data::Dumper;

sub config_filename		{ shift->{config_filename}		}
sub data_dir			{ shift->{data_dir}			}
sub node_dir			{ shift->{node_dir}			}
sub project_dir			{ shift->{project_dir}			}
sub nodes			{ shift->{nodes}			}
sub projects			{ shift->{projects}			}
sub job_id			{ shift->{job_id}			}
sub project_id			{ shift->{project_id}			}
sub in_job_control		{ shift->{in_job_control}		}
sub node_check_watcher		{ shift->{node_check_watcher}		}

sub set_config_filename		{ shift->{config_filename}	= $_[1] }
sub set_data_dir		{ shift->{data_dir}		= $_[1] }
sub set_node_dir		{ shift->{node_dir}		= $_[1] }
sub set_project_dir		{ shift->{project_dir}		= $_[1] }
sub set_nodes			{ shift->{nodes}		= $_[1] }
sub set_projects		{ shift->{projects}		= $_[1] }
sub set_job_id			{ shift->{job_id}		= $_[1] }
sub set_project_id		{ shift->{project_id}		= $_[1] }
sub set_in_job_control		{ shift->{in_job_control}	= $_[1] }
sub set_node_check_watcher	{ shift->{node_check_watcher}	= $_[1] }

{
	my $MASTER_OBJECT;
	
	sub get_master {
		my $class = shift;
		# only one master object per process, so return the object
		# directly if already created.
		return $MASTER_OBJECT if $MASTER_OBJECT;

		my %par = @_;
		my ($logger) = @par{'logger'};

		my $self = {
			data_dir	  => $ENV{HOME}."/.dvdrip-master",
			node_dir	  => $ENV{HOME}."/.dvdrip-master/nodes",
			project_dir	  => $ENV{HOME}."/.dvdrip-master/projects",
			config_filename	  => $ENV{HOME}."/.dvdrip-master/master.conf",
			nodes		  => [],
			projects          => [],
			job_id		  => 0,
			logger		  => $logger,
		};

		bless $self, $class;

		if ( not -d $self->data_dir ) {
			mkdir ($self->data_dir, 0755) or
				croak "can't create directory '".$self->data_dir."'";

		}

		if ( not -d $self->node_dir ) {
			mkdir ($self->node_dir, 0755) or
				croak "can't create directory '".$self->node_dir."'";

		}

		if ( not -d $self->project_dir ) {
			mkdir ($self->project_dir, 0755) or
				croak "can't create directory '".$self->project_dir."'";

		}

		$self->log (__"Master daemon activated");

		$self->load;

		$MASTER_OBJECT = $self;

		$self->enable_node_check
			if not $self->node_check_unnecessary;

		return $self;
	}

}

sub check_prerequisites {
	my $class = shift;
	
	# check for suid root /usr/sbin/fping
	croak "/usr/sbin/fping missing"
		if not -f "/usr/sbin/fping";
	croak "no permission to execute /usr/sbin/fping"
		if not -x "/usr/sbin/fping";

	my ($mode,$uid) = (stat("/usr/sbin/fping"))[2,4];
	my $suid = $mode & 04000;

	croak "/usr/sbin/fping is not suid root"
		if not $suid or $uid != 0;

	1;
}

sub node_check_unnecessary {
	my $self = shift; $self->trace_in;

	return if Video::DVDRip::RPC::Server->instance->clients_connected;
	return if @{$self->job_get_unfinished_projects};
	return 1;
}

sub enable_node_check {
	my $self = shift; $self->trace_in;

	return if $self->node_check_watcher;

	$self->node_check;

	my $watcher = Event->timer (
		interval => 10,
		cb       => sub { $self->node_check },
		desc     => "node check timer"
	);

	$self->log ("Node check watcher enabled");

	$self->set_node_check_watcher ( $watcher );

	1;
}

sub disable_node_check {
	my $self = shift; $self->trace_in;
	
	return if not $self->node_check_watcher;

	$self->node_check_watcher->cancel;
	$self->set_node_check_watcher(undef);

	$self->log (__"Node check watcher disabled");

	1;
}

sub node_check {
	my $self = shift; $self->trace_in;
	
	my $nodes_list;
	foreach my $node ( @{$self->nodes} ) {
		$nodes_list .= $node->hostname." "
			if $node->state ne 'stopped' and
			   not $node->is_master;
	}
	
	return 1 if not $nodes_list;

	my $command = "/usr/sbin/fping $nodes_list";
	
	my $buffer;

	Video::DVDRip::Cluster::Pipe->new (
		timeout      => 8,
		command      => $command,
		no_log       => 1,
		cb_line_read => sub {
			$buffer .= $_[0]."\n";
			1;
		},
		cb_finished => sub {
			if ( $buffer =~ /^\s*$/ ) {
				$self->log (__"Warning: node check fping reported nothing");
				return;
			}
			my $node_name;
			my $idle_nodes;
			foreach my $node ( @{$self->nodes} ) {
				next if $node->state eq 'stopped';
				if ( $node->is_master ) {
					++$idle_nodes if $node->state eq 'idle';
					next;
				}

				$node_name = $node->hostname;
				if ( $buffer =~ /^$node_name\s+is\s+alive/m ) {
					if ( not $node->alive and $node->answered_last_ping == 2 ) {
						$self->log (__x("Node '{node_name}' is now online.", node_name => $node_name));
						$node->set_alive(1);
					}
					if ( not $node->alive and $node->answered_last_ping == 1 ) {
						$self->log (__x("Node '{node_name}' is still reachable. Will be online in 10 seconds.", node_name => $node_name));
						$node->set_answered_last_ping ( 2 );
					}
					if ( not $node->alive and not $node->answered_last_ping ) {
						$self->log (__x("Node '{node_name}' is now reachable. Will be online in 20 seconds.", node_name => $node_name));
						$node->set_answered_last_ping ( 1 );
					}
					if ( $node->alive == 0.5 ) {
						$self->log (__x("Node '{node_name}' is Ok again", node_name => $node_name));
						$node->set_alive(1);
					}
				} else {
					$node->set_answered_last_ping ( 0 );
					if ( $node->alive == 0.5 ) {
						$self->log (__x("Warning: Node '{node_name}' is unreachable", node_name => $node_name))
							if $node->alive or $node->state eq 'unknown';
						$node->set_alive(0);
					} elsif ( $node->alive ) {
						$self->log (__x("Warning: Node '{node_name}' possibly offline", node_name => $node_name));
						$node->set_alive(0.5);
					} else {
						$node->set_alive(0);
					}
				}
				++$idle_nodes if $node->state eq 'idle';
			}

			$self->disable_node_check
				if $self->node_check_unnecessary;

			$self->job_control if $idle_nodes and
					      not $self->in_job_control;
		},
	)->open;
	
	1;
}

sub hello {
	my $self = shift; $self->trace_in;
	
	$self->enable_node_check;
	
	1;
}

sub load {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->config_filename;
	if( not -f $filename ) {
		$self->save;
	}
	
	my $fh = FileHandle->new;
	open ($fh, $filename)
		or croak "can't read master config file '$filename'";
	my $data_blob = join ('', <$fh>);
	close $fh;
	
	my $data;
	$data = eval $data_blob;
	croak "Error loading master config file '$filename': $@" if $@;
	
	$self->set_job_id ( $data->{job_id} );
	$self->set_project_id ( $data->{project_id} );

	$self->load_nodes;
	$self->load_projects ( project_order => $data->{project_order} );
	
	1;
}

sub save {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->config_filename;
	
	my @project_order = map { $_->filename } @{$self->projects};
	
	my $data = {
		job_id        => $self->job_id,
		project_id    => $self->project_id,
		project_order => \@project_order,
	};

	my $dd = Data::Dumper->new ( [$data], ['data'] );
	$dd->Indent(1);
	my $data_blob = $dd->Dump;
	
	my $fh = FileHandle->new;
	open ($fh, "> $filename")
		or croak "can't write master config file '$filename'";
	print $fh $data_blob;
	close $fh;
	
	1;
}

sub load_nodes {
	my $self = shift; $self->trace_in;
	
	my $dir = $self->node_dir;
	
	my @nodes;
	foreach my $file ( <$dir/*> ) {
		$self->log (__x("Loading node file '{file}'", file => $file));
		my $node = Video::DVDRip::Cluster::Node->new_from_file (
			filename  => $file,
		);
		$node->reset;
		push @nodes, $node;
	}

	$self->set_nodes( \@nodes );
	
	1;
}

sub load_projects {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project_order) = @par{'project_order'};

	my $dir = $self->project_dir;

	my @projects;	
	foreach my $filename ( @{$project_order} ) {
		next if not -r $filename;
		$self->log (__x("Loading project file '{filename}'", filename => $filename));
		my $project = Video::DVDRip::Cluster::Project->new_from_file (
			filename  => $filename,
		);
		$project->reset_jobs;
		$project->determine_state;
		push @projects, $project;
	}

	$self->set_projects (\@projects);
	
	1;
}

sub add_node {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($node) = @par{'node'};
	
	my $filename = $self->node_dir.'/'.$node->name.'.node';

	croak "msg: ".__"Node must have a name" if $node->name eq '';
	croak "msg: ".__"Node with this name already exists" if -f $filename;
	
	$node->set_state ("idle") if $node->is_master;
	
	push @{$self->nodes}, $node;
	$node->set_filename ($filename);
	$node->save;
	
	$self->log (
		__x("Node '{node_name}' saved to '{filename}'",
		node_name => $node->name, filename => $filename)
	);
	
	1;
}

sub remove_node {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($node) = @par{'node'};

	my $i=0;
	foreach my $n ( @{$self->nodes} ) {
		last if $n == $node;
		++$i;
	}
	
	croak "Unknown node $node" if $i == @{$self->nodes};
	
	unlink $node->filename;

	splice @{$self->nodes}, $i, 1;

	1;
}

sub get_project_index {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project) = @par{'project'};
	
	my $projects = $self->projects;
	
	my $i = 0;
	foreach my $p ( @{$projects} ) {
		last if $p == $project;
		++$i;
	}
	
	croak "Unknown project $project" if $i == @{$projects};
	
	return $i;
}

sub project_by_id {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($id) = @par{'id'};
	
	my $p;
	foreach $p ( @{$self->projects} ) {
		return $p if $p->id == $id;
	}
	
	croak "Unknown project id $id";
}

sub add_project {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project) = @par{'project'};
	
	push @{$self->projects}, $project;
	
	my $job_id = $self->set_project_id ( 1 + $self->project_id );
	my $filename = sprintf (
		"%s/%08d-%s.rip",
		$self->project_dir,
		$job_id,
		$project->name
	);

	$project->set_filename ($filename);
	$project->set_state ('not scheduled');
	$project->set_id ($job_id);

	# save changes to project
	$project->save;

	$self->log (__x("Project with filename '{filename}' added", filename => $filename));
	
	# save new state
	$self->save;

	1;
}

sub move_up_project {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project) = @par{'project'};
	
	my $i = $self->get_project_index ( project => $project );

	# already on top?	
	return if $i == 0;
	
	# move project up
	my $projects = $self->projects;
	@{$projects}[$i,$i-1] = @{$projects}[$i-1,$i];

	# save new state
	$self->save;

	1;
}

sub move_down_project {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project) = @par{'project'};
	
	my $i = $self->get_project_index ( project => $project );
	
	# already on bottom?
	my $projects = $self->projects;
	return if $i == @{$projects} - 1;
	
	# move project up
	@{$projects}[$i,$i+1] = @{$projects}[$i+1,$i];
	
	# save new state
	$self->save;

	1;
}

sub schedule_project {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project) = @par{'project'};
	
	# check for existence
	$self->get_project_index ( project => $project );

	# change project state
	$project->set_state ( 'waiting' );
	
	# change state of all jobs
	$_->set_state ('waiting') foreach @{$project->jobs};
	
	# save project's state
	$project->save;

	# maybe the job controller can dispose some work now...
	$self->job_control;

	1;
}

sub remove_project {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project) = @par{'project'};
	
	# check for existence
	my $i = $self->get_project_index ( project => $project );

	# check project state
	return   if $project->state ne 'waiting' and
		    $project->state ne 'not scheduled' and
		    $project->state ne 'merged' and
		    $project->state ne 'audio processed' and
		    $project->state ne 'avi splitted' and
	            $project->state ne 'finished';

	unlink $project->filename;
	splice @{$self->projects}, $i, 1;

	$self->log (__x("Project {project} removed", project => $project->label));

	1;
}

sub get_projects_lref {
	my $self = shift; $self->trace_in;
	
	my $nr;
	my @projects;
	foreach my $project ( @{$self->projects} ) {
		push @projects, [
			$nr++,
			$project->id,
			$project->label,
			scalar(@{$project->jobs}),
			$project->state,
		];
	}
	
	return \@projects;
}

sub get_jobs_lref {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($project_id) = @par{'project_id'};
	
	my $project = $self->project_by_id ( id => $project_id );
	
	return $project->get_jobs_lref;
}

sub get_nodes_lref {
	my $self = shift; $self->trace_in;
	
	my $nr;
	my @nodes;
	foreach my $node ( @{$self->nodes} ) {
		push @nodes, [
			$nr++,
			$node->name,
			($node->assigned_job ? $node->assigned_job->id : undef),
			($node->assigned_job ? $node->assigned_job->progress : undef),
		];
	}
	
	return \@nodes;
}

sub job_control {
	my $self = shift; $self->trace_in;
	return if $self->in_job_control;

	$self->set_in_job_control(1);

	# 1. move waiting projects before not scheduled projects
	$self->job_sort_projects;

	# 2. delegate pending jobs
	$self->job_delegate_pending_jobs;

	$self->set_in_job_control(0);

	1;
}

sub job_sort_projects {
	my $self = shift; $self->trace_in;
	
	# divide projects in order to not scheduled and scheduled projects
	my @not_scheduled;
	my @scheduled;
	my @finished;
	foreach my $project ( @{$self->projects} ) {
		if ( $project->state eq 'not scheduled' ) {
			push @not_scheduled, $project;
		} elsif ( $project->state eq 'finished' ) {
			push @finished, $project;
		} else {
			push @scheduled, $project;
		}
	}
	
	# define project list with scheduled first, then the not
	# scheduled projects
	my @projects = ( @scheduled, @not_scheduled, @finished );
	
	$self->set_projects ( \@projects );

	1;
}

sub job_delegate_pending_jobs {
	my $self = shift; $self->trace_in;
	
	# get idle nodes
	my $nodes = $self->job_get_idle_nodes;

	# nothing to do if no node is idle
	return 1 if not @{$nodes};	

	# get waiting projects
	my $projects = $self->job_get_unfinished_projects;

	# nothing to do if no project is in the queue for processing
	return 1 if not @{$projects};	

	# in this array we remember local jobs which
	# are skipped due to a lack of local nodes
	my @skipped_local_access_jobs;

	# now check for jobs for each project, in order of priority
	foreach my $project ( @{$projects} ) {

		# get out here if no idles nodes are left
		last if not @{$nodes};

		# create list of jobs, which are waiting, with local_access
		# jobs first (because we actively search local nodes later, 
		# this prevents blocking a local node with a non local job,
		# just a round before we try to schedule a local job).
		my (@local_jobs, @other_jobs);

		foreach my $job ( @{$project->jobs} ) {
			# skip jobs that are finished or running
			next if $job->state eq 'finished' or
				$job->state eq 'running' or
				$job->state eq 'aborted';

			# We do not check the dependency state of
			# the job here, because this is expensive.
			# This is done later in the scheduler loop,
			# because it exits if no idle nodes are left,
			# which is regularly very early, so computing
			# the dependecies here in advance makes no
			# sense at all.

			if ( $job->prefer_local_access ) {
				push @local_jobs, $job;
			} else {
				push @other_jobs, $job;
			}
		}

		# check if we can start jobs
		foreach my $job ( @local_jobs, @other_jobs ) {
			last if not @{$nodes};
			next if not $job->dependency_ok;

			if ( $job->prefer_local_access ) {
				# search a node with local access
				my $i = 0;
				foreach my $node ( @{$nodes} ) {
					last if $node->data_is_local;
					++$i;
				}
				if ( $i < @{$nodes} ) {
					# found one: start the job on it
					$job->start_job (
						node => splice (@{$nodes}, $i, 1)
					);
					next;

				} else {
					# no local node found. skip this job.
					# schedule it later if we have idle
					# nodes left after this round.
					push @skipped_local_access_jobs, $job;
					next;
				}

			}

			# this is a normal job: start it on the next idle node
			$job->start_job ( node => shift @{$nodes} );
		}
	}

	# do we have skipped local jobs and have idle nodes left?
	if ( @{$nodes} and @skipped_local_access_jobs ) {
		foreach my $job ( @skipped_local_access_jobs ) {
			$job->start_job ( node => shift @{$nodes} );
			last if not @{$nodes};
		}
	}

	1;
}

sub job_get_idle_nodes {
	my $self = shift; $self->trace_in;
	
	# create a list of nodes which have the 'idle' state
	my @idle_nodes;
	foreach my $node ( @{$self->nodes} ) {
		push @idle_nodes, $node if $node->state eq 'idle';
	}
	
	@idle_nodes = sort { $b->speed <=> $a->speed } @idle_nodes;

	return \@idle_nodes;
}

sub job_get_unfinished_projects {
	my $self = shift; $self->trace_in;
	
	my @projects;

	foreach my $project ( @{$self->projects} ) {
		push @projects, $project
			if $project->state eq 'waiting' or
			   $project->state eq 'running';
	}

	$self->enable_node_check if @projects;

	return \@projects;
}

sub shutdown {
	my $self = shift; $self->trace_in;
	
	Event->timer (
		interval => 2,
		cb       => sub { Event::unloop_all() },
		desc     => "dvd::rip shutdown timer"
	);

	$self->log (__"Cluster control daemon will shutdown in 2 seconds...");

	1;
	
}

sub get_next_job_id {
	my $self = shift; $self->trace_in;
	
	my $job_id = $self->set_job_id ( 1 + $self->job_id );
	$self->save;
	
	return $job_id;
}

sub get_online_nodes_cnt {
	my $self = shift; $self->trace_in;

	my $cnt = 0;	
	foreach my $node ( @{$self->nodes} ) {
		++$cnt if $node->state ne 'unknown' and
			  $node->state ne 'offline';
	}
	
	return $cnt;
}



1;
