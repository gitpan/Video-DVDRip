# $Id: TranscodeVideo.pm,v 1.3 2002/09/22 09:40:44 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::TranscodeVideo;

# That's Perl! The job classes inherit from this class,
# which is decided at *runtime* - this way standard and
# cluster mode can share the same job execution system
# by inserting the cluster logic dynamically into the
# inheritence line... great stuff!

BEGIN {	eval "use base $Video::DVDRip::JobClass" }

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub pass			{ shift->{pass}				}
sub single_pass			{ shift->{single_pass}			}
sub split			{ shift->{split}			}

sub set_chapter			{ shift->{chapter}		= $_[1]	}
sub set_pass			{ shift->{pass}			= $_[1]	}
sub set_single_pass		{ shift->{single_pass}		= $_[1]	}
sub set_split			{ shift->{split}		= $_[1]	}

sub type {
	return "transcode";
}

sub info {
	my $self = shift;

	my $info = "Transcoding video - title #".$self->title->nr;
	my $chapter = $self->chapter;
	
	if ( $chapter ) {
		$info .= ", chapter #$chapter";
	}

	if ( $self->single_pass ) {
		$info .= ", single pass";
	} else {
		$info .= ", pass ".$self->pass;
	}

	return $info;
}

sub init {
	my $self = shift;
	
	my $title   = $self->title;
	my $chapter = $self->chapter;

	$self->set_progress_show_fps ( 1 );

	my $max_value;
	if ( not $chapter ) {
		if ( $title->tc_start_frame ne '' or
		     $title->tc_end_frame ne '' ) {
		     	$max_value = $title->tc_end_frame || $title->frames;
			$max_value = $max_value - $title->tc_start_frame
				     	if $title->has_vob_nav_file;
			$max_value ||= $title->frames;
		} else {
			$max_value = $title->frames;
		}
	} else {
		$max_value = $title->chapter_frames->{$chapter};
	}

	$self->set_progress_max ( $max_value );

	1;
}

sub command {
	my $self = shift;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);

	my $command = $title->get_transcode_command (
		pass  => $self->pass,
		split => $self->split,
		
	);

	$title->set_actual_chapter (undef);

	return $command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $line =~ /split.*?mapped.*?-c\s+\d+-(\d+)/ ) {
		$self->set_progress_max($1);
		$self->set_progress_start_time(time);

	} elsif ( $line =~ /\[\d{6}-(\d+)\]/ ) {
		$self->set_progress_cnt($1);
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
