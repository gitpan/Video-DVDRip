# $Id: GrabPreviewFrame.pm,v 1.5.2.2 2006/03/18 11:23:01 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::GrabPreviewFrame;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job;

use Carp;
use strict;

sub frame_nr			{ shift->{frame_nr}			}
sub set_frame_nr		{ shift->{frame_nr}		= $_[1]	}

sub slow_mode			{ shift->{slow_mode}			}
sub set_slow_mode		{ shift->{slow_mode}		= $_[1]	}

sub type {
	return "grab_preview";
}

sub info {
	my $self = shift;

	my $info =__"Grabbing preview";
	$info .= " - ".__x("title #{title}", title => $self->title->nr);
	$info .= " ,".__x("frame #{frame}", frame => $self->title->preview_frame_nr);

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	if ( $title->project->rip_mode eq 'rip' and
	     $title->has_vob_nav_file and
	     !$title->tc_force_slow_grabbing ) {
		$self->set_progress_show_fps ( 0 );
		$self->set_progress_max ( 5 );
		$self->set_progress_cnt ( 5 );
		$self->set_slow_mode ( 0 );
	} else {
		$self->set_progress_show_fps ( 1 );
		$self->set_progress_max ( $self->title->preview_frame_nr );
		$self->set_slow_mode ( 1 );
	}
	
	1;
}

sub command {
	my $self = shift;

	return $self->title->get_take_snapshot_command (
		frame => $self->title->preview_frame_nr
	);
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $self->slow_mode ) {
		$line =~ /\[\d+-(\d+)\]/;
		$self->set_progress_cnt($1) if $1;
	}
	
	if ( $line =~ /encoded\s+(\d+)\s+frame/ ) {
		if ( $1 == 1 ) {
			$self->set_operation_successful (1);
		} else {
			$self->set_error_message (
				__"transcode can't find this frame. ".
				  "Try forcing slow frame grabbing."
			);
			$self->abort_job;
		}
	}

	1;	
}

sub commit {
	my $self = shift;
	
	$self->title->calc_snapshot_bounding_box;
	
	1;
}

1;
