# $Id: Pipe.pm,v 1.10.2.2 2003/02/23 21:39:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Pipe;

use base Video::DVDRip::Base;

use Event;
use constant NICE => -1;

use FileHandle;

use Carp;
use strict;

my $LIFO_SIZE = 40;

sub command			{ shift->{command}			}
sub timeout			{ shift->{timeout}			}
sub cb_finished			{ shift->{cb_finished}			}
sub cb_line_read		{ shift->{cb_line_read}			}

sub lifo			{ shift->{lifo}				}
sub lifo_idx			{ shift->{lifo_idx}			}

sub fh				{ shift->{fh}				}
sub pid				{ shift->{pid}				}
sub line_buffer			{ shift->{line_buffer}			}
sub event_waiter		{ shift->{event_waiter}			}

sub set_fh			{ shift->{fh}			= $_[1]	}
sub set_pid			{ shift->{pid}			= $_[1]	}
sub set_event_waiter		{ shift->{event_waiter}		= $_[1]	}
sub set_line_buffer		{ shift->{line_buffer}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($command, $cb_line_read, $cb_finished, $timeout) =
	@par{'command','cb_line_read','cb_finished','timeout'};

	my $self = {
		timeout		=> $timeout,
		command		=> $command,
		cb_line_read	=> $cb_line_read,
		cb_finished	=> $cb_finished,
		event_waiter	=> undef,
		output_lifo	=> [ ( undef ) x $LIFO_SIZE ],
		lifo_idx	=> -1,
	};

	return bless $self, $class;
}

sub open {
	my $self = shift;

	my $timeout = $self->timeout;
	my $command = $self->command;

	my $fh  = FileHandle->new;
	my $pid;
	
	# we use fork & exec, because we want to have
	# STDERR on STDOUT in the child.
	$pid = open($fh, "-|");
	croak "can't fork child process" if not defined $pid;
		
	if ( not $pid ) {
		# we are the child. Copy STDERR to STDOUT
		close STDERR;
		open (STDERR, ">&STDOUT")
			or croak "can't dup STDOUT to STDERR";
		my $command = $self->command;
		$command = "dr_exec $command" if $command !~ /dr_exec/;
		exec ($self->command)
			or croak "can't exec program: $!";
	}

	# we are the parent and go further, holding the
	# pid of our child in $pid

	$self->set_fh($fh);
	$self->set_pid($pid);

	my %timeout_options;
	%timeout_options = (
		timeout 	=> $timeout,
		timeout_cb	=> sub { $self->timeout_expired },
	) if $timeout;

	$self->set_event_waiter (
	    Event->io (
		fd      	=> $fh,
		poll    	=> 'r',
		desc 		=> "command execution",
		nice    	=> NICE,
		cb   		=> sub { $self->input ( $_[1] ) },
		%timeout_options,
	    )
	);

	$self->log (3, "execute command: $command");

	return $self;
}

sub add_lifo_line {
	my $self = shift;

	$self->{lifo}->[
		$self->{lifo_idx} = ($self->{lifo_idx} + 1) % $LIFO_SIZE
	] = $_[0];

	1;
}

sub output_tail {
	my $self = shift;
	
	my $tail = '';
	my $lifo_idx = $self->{lifo_idx};
	my $i = $lifo_idx;

	while () {
		last if not defined $self->{lifo}->[$i];
		$tail .= $self->{lifo}->[$i++];
		$i = $i % $LIFO_SIZE;
		last if $i == $lifo_idx;
	}
	
	return $tail;
}

sub timeout_expired {
	my $self = shift;

	$self->log ("Command cancelled due to timeout");

	kill 15, $self->pid;
	$self->cancel;

	1;
}

sub input {
	my $self = shift;
	my ($abort) = @_;

	my $fh = $self->fh;

	# eof or abort?
	if ( $abort or eof ($fh) ) {
		$self->close;
		my $cb_finished = $self->cb_finished;
		&$cb_finished ();
		return;
	}

	# read next line
	my ($rc, $last_was_eol, $got_empty_line);
	my $line_buffer = $self->line_buffer;

	while ( not eof($fh) and defined ($rc = getc($fh)) ) {
		last if $last_was_eol and $rc ne "\n" and $rc ne "\r";
		if ( $rc ne "\n" and $rc ne "\r" ) {
			$line_buffer .= $rc;
		} elsif ( $last_was_eol ) {
			$got_empty_line = 1;
			$rc = '';
			last;
		} else {
			$last_was_eol = 1;
		}
		last if $line_buffer =~ /password: $/;
	}

	# get job's PID
	my ($pid) = ( $line_buffer =~ /DVDRIP_JOB_PID=(\d+)/ );
	if ( defined $pid ) {
		$self->set_pid ( $pid );
		$self->log ("Job has PID $pid");
		$line_buffer =~ s/DVDRIP_JOB_PID=(\d+)//;
		$rc =~ s/DVDRIP_JOB_PID=(\d+)//;
	}

	# append line to lifo
	$self->add_lifo_line ( $line_buffer."\n" );

	# call the line_read callback, if we have one
	my $cb_line_read = $self->cb_line_read;
	&$cb_line_read($line_buffer) if $cb_line_read;
	&$cb_line_read('')           if $got_empty_line and $cb_line_read;

	$self->set_line_buffer ($rc);

	1;
}

sub close {
	my $self = shift;
	
	my $fh = $self->fh;
	
	$self->event_waiter->cancel if $self->event_waiter;
	$self->set_event_waiter (undef);

	close $fh;
	waitpid $self->pid, 0;

	$self->log (5, "command finished: ".$self->command);
	
	1;
}

sub cancel {
	my $self = shift;

	my $pid = $self->pid;

	if ( $pid ) {
		$self->log ("Aborting command. Sending signal 1 to PID $pid...");
		kill 1, $pid;
	}

	$self->close;

	1;
}

1;
