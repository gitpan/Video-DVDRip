# $Id: Pipe.pm,v 1.5 2002/10/06 11:46:40 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Pipe;

use base Video::DVDRip::GUI::Base;

use strict;
use Carp;
use Data::Dumper;
use Cwd;
use FileHandle;

use POSIX qw(:errno_h);

sub fh				{ shift->{fh}				}
sub command			{ shift->{command}			}
sub gtk_input			{ shift->{gtk_input}			}
sub need_output			{ shift->{need_output}			}
sub output			{ shift->{output}			}
sub cb_line_read		{ shift->{cb_line_read}			}
sub cb_finished			{ shift->{cb_finished}			}
sub pid				{ shift->{pid}				}

sub set_fh			{ shift->{fh}			= $_[1] }
sub set_command			{ shift->{command}		= $_[1]	}
sub set_gtk_input		{ shift->{gtk_input}		= $_[1] }
sub set_need_output		{ shift->{need_output}		= $_[1]	}
sub set_output 			{ shift->{output}		= $_[1]	}
sub set_cb_line_read		{ shift->{cb_line_read}		= $_[1]	}
sub set_cb_finished		{ shift->{cb_finished}		= $_[1]	}
sub set_pid			{ shift->{pid}			= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($command, $need_output, $cb_line_read, $cb_finished) =
	@par{'command','need_output','cb_line_read','cb_finished'};

	my $self = {
		command			=> $command,
		need_output		=> $need_output,
		cb_line_read		=> $cb_line_read,
		cb_finished		=> $cb_finished,
 	};
	
	return bless $self, $class;
}

sub open {
	my $self = shift;

	my $fh  = FileHandle->new;
	my $pid;
	
	# we use fork & exec, because we want to have
	# STDERR on STDOUT in the child.
	$pid = open($fh, "-|");
	croak "can't fork child process" if not defined $pid;

	$fh->blocking(0);
		
	if ( not $pid ) {
		# we are the child. Copy STDERR to STDOUT
		close STDERR;
		open (STDERR, ">&STDOUT")
			or croak "can't dup STDOUT to STDERR";
		
		# simply call exec with one argument, this
		# will execute the command using a shell
		exec ($self->command)
			or croak "can't exec program: $!";
	}

	$self->log ("Executing command: ".$self->command. " (PID=$pid)");

	$self->set_pid ( $pid );
	$self->set_fh ( $fh );
	$self->set_output ( "" );
	
	Gtk::Gdk->input_remove ( $self->gtk_input )
		if defined $self->gtk_input;

	$self->set_gtk_input (
		Gtk::Gdk->input_add (
			$fh->fileno,
			'read', sub { $self->progress }
		)
	);

	1;
}

sub progress {
	my $self = shift; $self->trace_in;

	my $fh = $self->fh;

	# read all date from the pipe
	my ($tmp, $buffer);
	while ( $fh->read ($tmp, 8192) ) {
		$buffer .= $tmp;
	}
	my $finished = $! != EAGAIN;

	# store output
	if ( $self->need_output ) {
		$self->{output} .= $buffer;
	} else {
		$self->{output} = substr($self->{output}.$buffer,-16384);
	}

	# our callbacks
	my $cb_finished  = $self->cb_finished;
	my $cb_line_read = $self->cb_line_read;

	# call callback if we got something
	&$cb_line_read ( $buffer ) if $buffer;

	# are we finished?
	if ( $finished ) {
		$self->close;
		&$cb_finished ();
		return;
	}


	1;
}

sub close {
	my $self = shift; $self->trace_in;

	Gtk::Gdk->input_remove ( $self->gtk_input ) if $self->gtk_input;

	close ($self->fh) if $self->fh;

	$self->set_gtk_input(undef);
	$self->set_fh ( undef );

	1;
}

sub cancel {
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
	$self->log ("Aborting command. Sending signal 2 to PID $child_pid...");
	kill 2, $child_pid;

	# close this pipe
	$self->close;

	1;
}

sub OLD_cancel {
	my $self = shift; $self->trace_in;

	kill 2, $self->pid;
	sleep 1;
	kill 9, $self->pid;

	$self->close;
	
	1;
}

1;
