# $Id: Pipe.pm,v 1.11 2005/07/23 08:14:15 joern Exp $

package Video::DVDRip::GUI::Pipe;

use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Base;

use strict;

use Carp;
use Cwd;
use FileHandle;
use Data::Dumper;

use Gtk2::Helper;
use POSIX qw(:errno_h);

sub fh				{ shift->{fh}				}
sub command			{ shift->{command}			}
sub args			{ shift->{args}				}
sub need_output			{ shift->{need_output}			}
sub output			{ shift->{output}			}
sub cb_line_read		{ shift->{cb_line_read}			}
sub cb_finished			{ shift->{cb_finished}			}
sub pid				{ shift->{pid}				}
sub watcher_tag			{ shift->{watcher_tag}			}

sub set_fh			{ shift->{fh}			= $_[1] }
sub set_command			{ shift->{command}		= $_[1]	}
sub set_args			{ shift->{args}			= $_[1]	}
sub set_need_output		{ shift->{need_output}		= $_[1]	}
sub set_output 			{ shift->{output}		= $_[1]	}
sub set_cb_line_read		{ shift->{cb_line_read}		= $_[1]	}
sub set_cb_finished		{ shift->{cb_finished}		= $_[1]	}
sub set_pid			{ shift->{pid}			= $_[1]	}
sub set_watcher_tag		{ shift->{watcher_tag}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($command, $need_output, $cb_line_read, $cb_finished) =
	@par{'command','need_output','cb_line_read','cb_finished'};
	my  ($args) =
	@par{'args'};

	my $self = {
		command			=> $command,
		args			=> ($args || []),
		need_output		=> $need_output,
		cb_line_read		=> $cb_line_read,
		cb_finished		=> $cb_finished,
 	};
	
	return bless $self, $class;
}

sub open {
	my $self = shift;

	my $fh  = FileHandle->new;
	
	# we use fork & exec, because we want to have
	# STDERR on STDOUT in the child.
	my $pid = open($fh, "-|");
	croak "can't fork child process" if not defined $pid;

	$fh->blocking(0);

	if ( not $pid ) {
		# we are the child. Copy STDERR to STDOUT
		close STDERR;
		open (STDERR, ">&STDOUT")
			or croak "can't dup STDOUT to STDERR";
		my $command = $self->command;
		exec ("dr_exec ".$self->command, @{$self->args})
			or croak "can't exec program: $!";
	}

	$self->log ("Executing command: ".$self->command);

	$self->set_fh ( $fh );
	$self->set_pid ( $pid );
	$self->set_output ( "" );

	$self->set_watcher_tag (
		Gtk2::Helper->add_watch (
			$fh->fileno,
			'in', sub { $self->progress; 1; }
		),
	);

	1;
}

sub close {
	my $self = shift;

	Gtk2::Helper->remove_watch ( $self->watcher_tag )
		if $self->watcher_tag;

	close ($self->fh)
		if $self->fh;

	$self->set_watcher_tag(undef);
	$self->set_fh ( undef );

	1;
}

sub cancel {
	my $self = shift;

	my $pid = $self->pid;

	if ( $pid ) {
		$self->log ("Aborting command. Sending signal 9 to PID $pid...");
		kill 9, $pid;
	}

	$self->close;

	1;
}

sub progress {
	my $self = shift;

	my $fh = $self->fh;

	# read all date from the pipe
	my ($tmp, $tmp_buffer);
	while ( $fh->read ($tmp, 8192) ) {
		$tmp_buffer .= $tmp;
	}
	my $finished = $! != EAGAIN;

	# store output
	if ( $self->need_output ) {
		$self->{output} .= $tmp_buffer;
	} else {
		$self->{output} = substr($self->{output}.$tmp_buffer,-16384);
	}

	# get job's PID
	my ($pid) = ( $tmp_buffer =~ /DVDRIP_JOB_PID=(\d+)/ );
	if ( defined $pid ) {
		$self->set_pid ( $pid );
		$self->log ("Job has PID $pid");
		$tmp_buffer =~ s/DVDRIP_JOB_PID=(\d+)\n//;
	}

	# prepend data from previous run
	my $buffer = $self->{buffer}.$tmp_buffer;

	# our callbacks
	my $cb_finished  = $self->cb_finished;
	my $cb_line_read = $self->cb_line_read;

	# process by line
	while ( $buffer =~ s/(.*)\n// ) {
		&$cb_line_read ( $1 ) if $cb_line_read;
	}

	# save rest of buffer
	$self->{buffer} = $buffer;

	# are we finished?
	if ( $finished ) {
		&$cb_finished ();
		return 1;
	}

	1;
}

1;
