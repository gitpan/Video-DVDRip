# $Id: Node.pm,v 1.14 2002/03/12 13:56:55 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Node;

use base Video::DVDRip::Base;

use Carp;
use strict;

use FileHandle;
use Data::Dumper;

sub state			{ shift->{state}			}
sub filename			{ shift->{filename}			}
sub name			{ shift->{name}				}
sub hostname			{ my $s = shift; $s->{hostname}||$s->{name} }
sub data_base_dir		{ shift->{data_base_dir}		}
sub is_master			{ shift->{is_master}			}
sub data_is_local		{ shift->{data_is_local}		}
sub username			{ shift->{username}			}
sub ssh_cmd			{ shift->{ssh_cmd}			}
sub speed			{ shift->{speed}			}
sub tc_options			{ shift->{tc_options}			}

sub progress_frames		{ shift->{progress_frames}		}
sub progress_frames_cnt		{ shift->{progress_frames_cnt}		}
sub progress_merge		{ shift->{progress_merge}		}
sub progress_start_time		{ shift->{progress_start_time}		}
sub assigned_job		{ shift->{assigned_job} 		}
sub assigned_chunk		{ shift->{assigned_chunk}		}

sub set_state			{ shift->{state}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_name			{ shift->{name}			= $_[1] }
sub set_hostname		{ shift->{hostname}		= $_[1] }
sub set_data_base_dir		{ shift->{data_base_dir}	= $_[1] }
sub set_is_master		{ shift->{is_master}		= $_[1] }
sub set_data_is_local		{ shift->{data_is_local}	= $_[1] }
sub set_username		{ shift->{username}		= $_[1] }
sub set_ssh_cmd			{ shift->{ssh_cmd}		= $_[1] }
sub set_speed			{ shift->{speed}		= $_[1] }
sub set_tc_options		{ shift->{tc_options}		= $_[1] }

sub set_progress_frames		{ shift->{progress_frames}	= $_[1] }
sub set_progress_frames_cnt	{ shift->{progress_frames_cnt}	= $_[1] }
sub set_progress_merge		{ shift->{progress_merge}	= $_[1] }
sub set_progress_start_time	{ shift->{progress_start_time}	= $_[1] }
sub set_assigned_job		{ shift->{assigned_job} 	= $_[1] }
sub set_assigned_chunk		{ shift->{assigned_chunk}	= $_[1] }

sub test_finished		{ shift->{test_finished}		}
sub test_result			{ shift->{test_result}			}

sub set_test_finished		{ shift->{test_finished}	= $_[1] }
sub set_test_result		{ shift->{test_result}		= $_[1] }

sub alive			{ shift->{alive}			}

sub set_alive {
	my $self = shift;
	my ($alive) = @_;
	
	my $was_alive = $self->alive;

	$self->{alive} = $alive;
	
	if ( not $alive ) {
		$self->stop if $was_alive;
		$self->set_state ("offline");
		$self->save;

	} elsif ( $self->state eq "offline" or
		  $self->state eq "unknown" ) {
		$self->set_state ("idle");
		$self->save;
	}

	1;
}

sub project_name {
	my $self = shift;
	my $job = $self->assigned_job;
	return "" if not $job;
	return $job->project->label;
}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($name, $hostname, $data_base_dir) =
	@par{'name','hostname','data_base_dir'};

	my  ($is_master, $username, $tc_options) =
	@par{'is_master','username','tc_options'};

	my $self = {
		name 		=> $name,
		hostname 	=> $hostname,
		data_base_dir 	=> $data_base_dir,
		is_master 	=> $is_master,
		username	=> $username,
		tc_options	=> $tc_options,
		alive           => 0,
	};
	
	bless $self, $class;
	
	$self->set_state ( "unknown" );
	
	return $self;
}

sub new_from_file {
	my $class = shift;
	my %par = @_;
	my ($filename) = @par{'filename'};
	
	confess "missing filename" if not $filename;
	
	my $self = bless {
		filename => $filename,
	}, $class;
	
	$self->load;
	
	$self->set_filename ($filename);

	return $self;
}

sub load {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->filename;
	croak "no filename set" if not $filename;
	croak "can't read $filename" if not -r $filename;
	
	my $fh = FileHandle->new;
	open ($fh, $filename) or croak "can't read $filename";
	my $data_blob = join ('', <$fh>);
	close $fh;

	my $data;
	$data = eval($data_blob);
	croak "can't load $filename. Perl error: $@" if $@;

	%{$self} = %{$data};

	1;
}

sub save {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->filename;
	confess "not filename set" if not $filename;
	
	my $assigned_job = $self->assigned_job;
	$self->set_assigned_job( undef );
	
	my $dd = Data::Dumper->new ( [$self], ['data'] );
	$dd->Indent(1);
	my $data = $dd->Dump;

	$self->set_assigned_job ( $assigned_job );

	my $fh = FileHandle->new;

	open ($fh, "> $filename") or confess "can't write $filename";
	print $fh $data;
	close $fh;
	
	1;
}

sub get_popen_code {
	my $self = shift;
	my %par = @_;
	my ($command) = @par{'command'};
	
	return $command if $self->is_master;

	my $username = $self->username;
	my $name     = $self->hostname;
	my $ssh_cmd  = $self->ssh_cmd  || 'ssh -C';

	$command =~ s/"/\\"/g;
	$command = qq{$ssh_cmd $username\@$name "$command"};
	
	return $command;
}

sub reset {
	my $self = shift;
	
	$self->set_state ('unknown')
		if $self->state ne 'stopped' and
		   $self->state ne 'aborted';

	1;
}

sub progress {
	my $self = shift;
	return "" if not $self->assigned_job;
	return $self->assigned_job->progress;
}

sub stop {
	my $self = shift;
	
	my $job = $self->assigned_job;

	$self->set_state ('stopped');
	$self->log ("Node '".$self->name."' stopped");
	$self->save;

	$job->stop if $job;
	
	1;
}

sub start {
	my $self = shift;
	
	croak "Can't start a non stopped node"
		if $self->state ne 'stopped' and
		   $self->state ne 'aborted';

	$self->log ("Node '".$self->name."' started");

	$self->set_state ('unknown');
	$self->save;

	Video::DVDRip::Cluster::Master->get_master->node_check;
	
	1;
}

sub job_info {
	my $self = shift;

	my $job = $self->assigned_job;

	my $info;
	if ( not $job ) {
		$info = $self->state;
	} else {
		$info = $job->nr.": ".$job->project->label.": ".$job->info;
	}

	return $info;
}

sub run_tests {
	my $self = shift;
	
	# First reset the finished flag
	$self->set_test_finished(0);

	if ( $self->state eq 'offline' ) {
		$self->set_test_finished(1);
		$self->set_test_result (
			"Node is offline. Can't test its configuration."
		);
		return;
	}

	# get test command for this node
	my $command = $self->get_test_command;

	my $popen_command = $self->get_popen_code ( command => $command );

	my $output = "";
	Video::DVDRip::Cluster::Pipe->new (
		command      => $popen_command,
		timeout	     => 5,
		cb_line_read => sub {
			$output .= $_[0]."\n";
		},
		cb_finished => sub {
			$self->parse_test_output;
			$self->set_test_result (
				$self->parse_test_output (
					output => $output
				)
			);
			$self->set_test_finished (1);
		}
	);

	1;
}

sub get_test_command {
	my $self = shift;
	my %par = @_;
	my ($data_base_dir) = @par{'data_base_dir'};
	
	my $command = "sh -c '";
	
	# 1. confirm ssh connection
	$command .= "echo --ssh_connect--; ".
		    "echo Ok; ".
		    "echo --ssh_connect--";
	
	# 2. get content of data_base_dir
	$data_base_dir ||= $self->data_base_dir;
	$command .= "echo --data_base_dir_content--; ".
		    "ls $data_base_dir 2>&1|sort; ".
		    "echo --data_base_dir_content--; ";
	
	# 3. try writing in the data_base_dir
	my $test_file = "$data_base_dir/".$self->name."-file-write-test";
	$command .= "echo --write_test--; ".
		    "echo node write test > $test_file 2>&1 && echo SUCCESS; ".
		    "rm -f $test_file; ".
		    "echo --write_test--; ";

	# 4. get transcode version
	$command .= "echo --transcode_version--; ".
		    "transcode -h 2>&1; ".
		    "echo --transcode_version--; ";

	$command .= "'";

	return $command;
}

sub parse_test_output {
	my $self = shift;
	my %par = @_;
	my ($output) = @par{'output'};

	# parse output
	my %result;
	foreach my $case ( qw ( ssh_connect data_base_dir_content
				write_test transcode_version ) ) {
		($result{$case}) = $output =~ m/--$case--\n(.*?)--$case--/s;
	}

	$result{output} = $output;

	return \%result;
}

1;