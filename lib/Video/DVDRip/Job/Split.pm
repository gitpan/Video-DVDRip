# $Id: Split.pm,v 1.4 2002/10/15 21:15:42 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::Split;

# That's Perl! The job classes inherit from this class,
# which is decided at *runtime* - this way standard and
# cluster mode can share the same job execution system
# by inserting the cluster logic dynamically into the
# inheritence line... great stuff!

BEGIN {	eval "use base $Video::DVDRip::JobClass" }

use Carp;
use strict;

sub ogg_pass			{ shift->{ogg_pass}			}
sub set_ogg_pass		{ shift->{ogg_pass}		= $_[1]	}


sub type {
	return "split";
}

sub info {
	my $self = shift;

	my $info;
	if ( $self->ogg_pass ) {
		$info = "split OGG pass ".$self->ogg_pass;
	} else {
		$info = "split AVI";
	}
	
	$info .= " - title #".$self->title->nr;

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	if ( $title->is_ogg ) {
		$self->set_progress_show_fps ( 0 );
		$self->set_progress_show_percent ( 1 );
		$self->set_progress_max(2000);
		$self->set_ogg_pass(1);
		return 1;
	}

	$self->set_ogg_pass(0);

	$self->set_progress_show_fps ( 1 );

	my $max_value;
	if ( $title->tc_start_frame ne '' or
	     $title->tc_end_frame ne '' ) {
	     	$max_value = $title->tc_end_frame;
		$max_value ||= $title->frames;
	} else {
		$max_value = $title->frames;
	}

	$self->set_progress_max ( $max_value );

	1;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	return $self->title->tc_target_size * 1024;
}

sub get_diskspace_freed {
	return 0;
}

sub command {
	my $self = shift;

	return $self->title->get_split_command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $self->ogg_pass ) {
		if ( $line =~ /second\s+pass/i ) {
			$self->set_ogg_pass( 2 );
			$self->set_progress_show_fps( 1 );
		}
		if ( $line =~ m!(\d+)/(\d+)! ) {
			$self->set_progress_cnt (
				1000 * ( $self->ogg_pass - 1 ) +
				int ( 1000 * $1 / $2 )
			);
		}
	} else {
		if ( $line =~ /\(\d{6}-(\d+)\),\s+(.*?)\[.*?$/ ) {
			$self->set_progress_cnt ($1);
		}
	}
	
	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
