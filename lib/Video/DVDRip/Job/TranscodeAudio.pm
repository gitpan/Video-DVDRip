# $Id: TranscodeAudio.pm,v 1.3 2002/10/15 21:15:53 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::TranscodeAudio;

use base Video::DVDRip::Job::TranscodeVideo;

use Carp;
use strict;

sub vob_nr			{ shift->{vob_nr}			}
sub set_vob_nr			{ shift->{vob_nr}		= $_[1]	}

sub avi_nr			{ shift->{avi_nr}			}
sub set_avi_nr			{ shift->{avi_nr}		= $_[1]	}

sub type {
	return "audio";
}

sub info {
	my $self = shift; $self->trace_in;

	my $info = "Transcoding audio - title #".$self->title->nr;
	my $nr      = $self->vob_nr;
	my $chapter = $self->chapter;
	
	$info .= ", track #$nr";
	$info .= ", chapter #$chapter" if $chapter;
	
	return $info;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	my $bitrate = $self->title->tc_audio_tracks
				  ->[$self->vob_nr]
				  ->tc_bitrate;

	my $runtime = $self->title->runtime;
	
	return int($runtime * $bitrate / 8);
}

sub get_diskspace_freed {
	return 0;
}

sub command {
	my $self = shift; $self->trace_in;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);

	my $command = $title->get_transcode_audio_command (
		vob_nr    => $self->vob_nr,
		target_nr => $self->avi_nr,
	);

	$title->set_actual_chapter (undef);

	return $command;
}

1;
