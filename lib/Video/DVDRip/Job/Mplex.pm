# $Id: Mplex.pm,v 1.1 2002/09/01 13:57:52 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::Mplex;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub set_chapter			{ shift->{chapter}		= $_[1]	}

sub type {
	return "mplex";
}

sub info {
	my $self = shift;

	my $info = "Multiplexing MPEG - title #".$self->title->nr;

	return $info;
}

sub init {
	my $self = shift;
	
	$self->set_progress_show_fps ( 0 );
	$self->set_progress_max ( 1 );
	$self->set_progress_cnt ( 1 );

	1;
}

sub command {
	my $self = shift;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);
	my $command = $title->get_mplex_command;
	$title->set_actual_chapter (undef);
	
	return $command;
}

sub parse_output {
	my $self = shift;
	my ($buffer) = @_;

	$self->set_operation_successful (1)
		if $buffer =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
