# $Id: TranscodeVideo.pm,v 1.6.2.1 2002/11/24 10:07:57 joern Exp $

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

use Video::DVDRip::InfoFile;

sub chapter			{ shift->{chapter}			}
sub pass			{ shift->{pass}				}
sub single_pass			{ shift->{single_pass}			}
sub split			{ shift->{split}			}
sub subtitle_test		{ shift->{subtitle_test}		}

sub set_chapter			{ shift->{chapter}		= $_[1]	}
sub set_pass			{ shift->{pass}			= $_[1]	}
sub set_single_pass		{ shift->{single_pass}		= $_[1]	}
sub set_split			{ shift->{split}		= $_[1]	}
sub set_subtitle_test		{ shift->{subtitle_test}	= $_[1]	}

sub type {
	return "transcode";
}

sub info {
	my $self = shift; $self->trace_in;

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
	my $self = shift; $self->trace_in;
	
	my $title   = $self->title;
	my $chapter = $self->chapter;

	$self->set_progress_show_fps ( 1 );

	my $max_value;
	
	if ( $self->subtitle_test ) {
		my ($from, $to) = $title->get_subtitle_test_frame_range;
		$max_value = $to - $from;
	} else {
		$max_value = $title->get_transcode_frame_cnt (
			chapter => $chapter
		);
	}

	if ( $chapter and not defined $max_value ) {
		$self->set_progress_show_percent(0);
		$max_value = 0;
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
	my $self = shift; $self->trace_in;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);

	my $command;
	
	if ( $self->subtitle_test ) {
		$command = $title->get_subtitle_test_transcode_command;
	} else {
		$command = $title->get_transcode_command (
			pass  => $self->pass,
			split => $self->split,
		);
	}

	$title->set_actual_chapter (undef);

	return $command;
}

sub parse_output {
	my $self = shift; $self->trace_in;
	my ($line) = @_;

	if ( $line =~ /split.*?mapped.*?-c\s+\d+-(\d+)/ ) {
		$self->set_progress_max($1);
		$self->set_progress_start_time(time);

	} elsif ( $line =~ /\[(\d{6}-)?(\d+)\]/ ) {
		$self->set_progress_cnt($2);
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift; $self->trace_in;
	
	my $title = $self->title;
	
	Video::DVDRip::InfoFile->new (
		title    => $title,
		filename => $title->info_file,
	)->write;
	
	1;
}

1;
