# $Id: Pipe.pm,v 1.6 2002/03/12 13:59:44 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
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

sub lifo			{ shift->{lifo}				}
sub lifo_idx			{ shift->{lifo_idx}			}
sub pid				{ shift->{pid}				}
sub fh				{ shift->{fh}				}
sub timeout			{ shift->{timeout}			}
sub cb_finished			{ shift->{cb_finished}			}
sub cb_line_read		{ shift->{cb_line_read}			}
sub command			{ shift->{command}			}

sub line_buffer			{ shift->{line_buffer}			}
sub set_line_buffer		{ shift->{line_buffer}		= $_[1]	}

sub event_waiter		{ shift->{event_waiter}			}
sub set_event_waiter		{ shift->{event_waiter}	= $_[1]		}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($command, $cb_line_read, $cb_finished, $timeout) =
	@par{'command','cb_line_read','cb_finished','timeout'};

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
		
		# simply call exec with one argument, this
		# will execute the command using a shell
		exec ($command)
			or croak "can't exec program: $!";
	}

	# we are the parent and go further, holding the
	# pid of our child in $pid

	my $self = bless {
		timeout		=> $timeout,
		command		=> $command,
		cb_line_read	=> $cb_line_read,
		cb_finished	=> $cb_finished,
		fh   		=> $fh,
		pid		=> $pid,
		event_waiter	=> undef,
		output_lifo	=> [ ( undef ) x $LIFO_SIZE ],
		lifo_idx	=> -1,
	}, $class;

	my %timeout_options;
	%timeout_options = (
		timeout 	=> $timeout,
		timeout_cb	=> sub { $self->timeout },
	) if $timeout;

	$self->{event_waiter} = Event->io (
		fd      	=> $fh,
		poll    	=> 'r',
		desc 		=> "command execution",
		nice    	=> NICE,
		cb   		=> sub { $self->input ( $_[1] ) },
		%timeout_options,
	);

	$self->log (3, "execute command: $command");

	return $self;
}

sub abort {
	my $self = shift;

	# this pid belong to the sh we started with exec
	my $pid = $self->pid;
	
	# but we want to have its child. We use pstree for that.
	my $pstree = qx[pstree -p $pid];
	$pstree =~ /\($pid\).*?\((\d+)/;
	my $child_pid = $1;

	# if there was no sh with a further child, we have to kill
	# our child process directly
	$child_pid ||= $pid;

	# kill the child
	$self->log ("Aborting command. Sending signal 15 to PID $child_pid...");
	kill 15, $child_pid;

	1;
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

sub timeout {
	my $self = shift;

	$self->log ("Command cancelled due to timeout");

	kill 15, $self->pid;
#	$self->abort;

	1;
}

sub input {
	my $self = shift;
	my ($abort) = @_;

	my $fh = $self->fh;

	# eof or abort?
	if ( $abort or eof ($fh) ) {
		my $cb_finished = $self->cb_finished;
		&$cb_finished if $cb_finished;
		$self->event_waiter->cancel;
		$self->set_event_waiter (undef);
		close $fh;
		$self->log (5, "command finished: ".$self->command);
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

	# append line to lifo
	$self->add_lifo_line ( $line_buffer."\n" );

	# call the line_read callback, if we have one
	my $cb_line_read = $self->cb_line_read;
	&$cb_line_read($line_buffer) if $cb_line_read;
	&$cb_line_read('')           if $got_empty_line and $cb_line_read;

	$self->set_line_buffer ($rc);

	1;
}

1;