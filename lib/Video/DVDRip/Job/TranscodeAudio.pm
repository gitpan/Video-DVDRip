# $Id: TranscodeAudio.pm,v 1.9 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::TranscodeAudio;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Job::TranscodeVideo;

use Carp;
use strict;

sub vob_nr			{ shift->{vob_nr}			}
sub avi_nr			{ shift->{avi_nr}			}

sub set_vob_nr			{ shift->{vob_nr}		= $_[1]	}
sub set_avi_nr			{ shift->{avi_nr}		= $_[1]	}

sub type {
	return "audio";
}

sub info {
	my $self = shift; $self->trace_in;

	my $info = __("Transcoding audio");
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

	my $nr      = $self->vob_nr;
	my $chapter = $self->chapter;
	
	$info .= ", ".__x("track #{nr}", nr => $nr);
	$info .= ", ".__x("chapter #{chapter}", chapter => $chapter) if $chapter;
	
	return $info;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	my $bitrate = $self->title->audio_tracks
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

sub commit {
	my $self = shift;

	if ( $self->bc ) {
		$self->bc->add_audio_size (
			bytes => -s $self->bc->title->target_avi_audio_file (
				vob_nr => $self->vob_nr,
				avi_nr => $self->avi_nr,
			)
		);
	}
	
	1;
}

1;
