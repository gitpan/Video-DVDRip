# $Id: Base.pm,v 1.10 2002/01/03 17:40:00 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Base;

use Carp;
use strict;
use FileHandle;
use IO::Pipe;
use Fcntl;

sub debug_level			{ shift->{debug_level}		}

sub set_debug_level {
	my $thing = shift;
	my $debug;
	if ( ref $thing ) {
		$thing->{debug_level} = shift if @_;
		$debug = $thing->{debug_level};
	} else {
		$Video::DVDRip::DEBUG = shift if @_;
		$debug = $Video::DVDRip::DEBUG;
	}
	
	if ( $debug ) {
		$Video::DVDRip::DEBUG::TIME = scalar(localtime(time));
		print STDERR
			"--- START ------------------------------------\n",
			"$$: $Video::DVDRip::DEBUG::TIME - DEBUG LEVEL $debug\n";
	}
	
	return $debug;
}

sub trace_in {
	my $thing = shift;
	my $debug = $Video::DVDRip::DEBUG;
	$debug = $thing->{debug_level} if ref $thing and $thing->{debug_level};
	return if $debug < 2;

	# Level 1: Methodenaufrufe
	if ( $debug == 2 ) {
		my @c1 = caller (1);
		my @c2 = caller (2);
		print STDERR "$$: TRACE IN : $c1[3] (-> $c2[3])\n";
	}
	
	# Level 2: Methodenaufrufe mit Parametern
	if ( $debug == 3 ) {
		package DB;
		my @c = caller (1);
		my $args = '"'.(join('","',@DB::args)).'"';
		my @c2 = caller (2);
		print STDERR "$$: TRACE IN : $c[3] (-> $c2[3])\n\t($args)\n";
	}
	
	1;
}

sub trace_out {
	my $thing = shift;
	my $debug = $Video::DVDRip::DEBUG;
	$debug = $thing->{debug_level} if ref $thing and $thing->{debug_level};
	return if $debug < 2;

	my @c1 = caller (1);
	my @c2 = caller (2);
	print STDERR "$$: TRACE OUT: $c1[3] (-> $c2[3])";

	if ( $debug == 2 ) {
		print STDERR " DATA: ", Dumper(@_);
	} else {
		print STDERR "\n";
	}
	
	1;
}

sub dump {
	my $self = shift;
	
	use Data::Dumper;
	print Dumper (@_);
	
	1;
}

sub print_debug {
	my $self = shift;
	
	if ( $self->debug_level ) {
		print STDERR join ("\n", @_), "\n";
	}
	
	1;
}

sub system {
	my $self = shift;
	my %par = @_;
	my  ($command, $err_ignore, $return_rc) =
	@par{'command','err_ignore','return_rc'};
	
	$self->print_debug ("executing command: $command");

	my $catch = `($command) 2>&1`;
	my $rc = $?;

	$self->print_debug ("got: rc=$rc catch=$catch");

	croak "Error executing command >$command< : $catch" if $rc;

	return $return_rc ? $? : $catch;
}

sub popen {
	my $self = shift;
	my %par = @_;
	my  ($command, $callback) =
	@par{'command','callback'};

	return $self->popen_with_callback (@_) if $callback;
	
	$self->print_debug ("executing command: $command");
	$self->log ("Executing command: $command");

	my $fh = FileHandle->new;
	open ($fh, "($command) 2>&1 |")
		or croak "can't fork $command";

	my $flags = '';
	fcntl($fh, F_GETFL, $flags)
		or die "Can't get flags: $!\n";
	$flags |= O_NONBLOCK;
	fcntl($fh, F_SETFL, $flags)
	    	or die "Can't set flags: $!\n";

	return $fh;
}

sub popen_with_callback {
	my $self = shift;
	my %par = @_;
	my  ($command, $callback, $catch_output) =
	@par{'command','callback','catch_output'};
	
	$self->print_debug ("executing command: $command");
	$self->log ("Executing command: $command");

	my $fh = FileHandle->new;
	open ($fh, "($command) 2>&1 |")
		or croak "can't fork $command";
	select $fh;
	$| = 1;
	select STDOUT;
	return $fh if not $callback;
	
	my ($output, $buffer);
	while ( read ($fh, $buffer, 512) ) {
		&$callback($buffer);
		$output .= $_ if $catch_output;
	}
	
	close $fh;
	
	return $output;
}

sub format_time {
	my $self = shift;
	my %par = @_;
	my ($time) = @par{'time'};
	
	my ($h, $m, $s);
	$h = int($time/3600);
	$m = int(($time-$h*3600)/60);
	$s = $time % 60;
	
	return sprintf ("%02d:%02d:%02d", $h, $m, $s);
}

sub stripped_exception {
	my $text = $@;
	$text =~ s/\s+at\s+.*?line\s+\d+//;
	return $text;
}

my $logger;

sub logger { $logger }

sub set_logger {
	my $self = shift;
	my ($set_logger) = @_;
	return $logger = $set_logger;
}

sub log {
	shift;
	return if not defined $logger;
	$logger->log(@_);
	1;
}

1;