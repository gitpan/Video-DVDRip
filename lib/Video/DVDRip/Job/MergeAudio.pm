# $Id: MergeAudio.pm,v 1.10 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::MergeAudio;

# That's Perl! The job classes inherit from this class,
# which is decided at *runtime* - this way standard and
# cluster mode can share the same job execution system
# by inserting the cluster logic dynamically into the
# inheritence line... great stuff!

BEGIN {	eval "use base $Video::DVDRip::JobClass" }

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub vob_nr			{ shift->{vob_nr}			}
sub avi_nr			{ shift->{avi_nr}			}
sub subtitle_test		{ shift->{subtitle_test}		}

sub set_chapter			{ shift->{chapter}		= $_[1]	}
sub set_vob_nr			{ shift->{vob_nr}		= $_[1]	}
sub set_avi_nr			{ shift->{avi_nr}		= $_[1]	}
sub set_subtitle_test		{ shift->{subtitle_test}	= $_[1]	}

sub type {
	return "merge audio";
}

sub info {
	my $self = shift;

	my $info    = "Merging audio - title #".$self->title->nr;
	my $nr      = $self->vob_nr;
	my $chapter = $self->chapter;
	
	$info .= ", audio track #$nr";
	$info .= ", chapter $chapter" if $chapter;
	
	return $info;
}

sub init {
	my $self = shift;
	
	my $title   = $self->title;
	my $chapter = $self->chapter;
		
	$self->set_progress_show_fps ( 1 );

	$self->set_progress_max (
		$title->get_transcode_frame_cnt ( chapter => $chapter )
	);

	1;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	my $video_size = $self->title->tc_target_size * 1024;

	return $video_size if $self->vob_nr == -1;
	
	my $bitrate = $self->title->audio_tracks
				  ->[$self->vob_nr]
				  ->tc_bitrate;

	my $runtime = $self->title->runtime;

	my $audio_size = int($runtime * $bitrate / 8);

	return $audio_size + $video_size;
}

sub get_diskspace_freed {
	my $self = shift; $self->trace_in;

	my $video_size = $self->title->tc_target_size * 1024;

	return $video_size;
}

sub command {
	my $self = shift;

	my $title = $self->title;

	$title->set_actual_chapter ( $self->chapter );
	$title->set_subtitle_test  ( $self->subtitle_test );
	
	my $command = $title->get_merge_audio_command (
		vob_nr        => $self->vob_nr,
		target_nr     => $self->avi_nr,
	);

	$title->set_actual_chapter (undef);
	$title->set_subtitle_test  (undef);

	return $command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $self->title->is_ogg ) {
		$self->set_progress_cnt ($1) if $line =~ /(\d+)/;
	} else {
		$self->set_progress_cnt ($1) if $line =~ /\(\d+-(\d+)\)/;
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
