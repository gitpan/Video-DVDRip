# $Id: Mplex.pm,v 1.7 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::Mplex;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job;

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub set_chapter			{ shift->{chapter}		= $_[1]	}

sub subtitle_test		{ shift->{subtitle_test}		}
sub set_subtitle_test		{ shift->{subtitle_test}	= $_[1]	}

sub type {
	return "mplex";
}

sub info {
	my $self = shift;

	my $info = __("Multiplexing MPEG");
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

	return $info;
}

sub init {
	my $self = shift;
	
	$self->set_progress_show_fps ( 0 );
	$self->set_progress_max ( 1 );
	$self->set_progress_cnt ( 1 );

	1;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	my $title = $self->title;

	$title->set_actual_chapter($self->chapter);

	my $bc = Video::DVDRip::BitrateCalc->new (
		title		=> $title,
		with_sheet	=> 0,
	);

	$bc->calculate_video_bitrate;

	$title->set_actual_chapter(undef);

	return int(($bc->video_size + $bc->non_video_size)*1024);
}

sub get_diskspace_freed {
	return 0;
}

sub command {
	my $self = shift;

	my $title = $self->title;

	$title->set_actual_chapter ( $self->chapter );
	$title->set_subtitle_test  ( $self->subtitle_test );

	my $command = $title->get_mplex_command;

	$title->set_actual_chapter (undef);
	$title->set_subtitle_test  (undef);

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
