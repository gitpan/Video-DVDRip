# $Id: CreateWav.pm,v 1.6 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::CreateWav;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Job::TranscodeVideo;

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub set_chapter			{ shift->{chapter}		= $_[1]	}

sub type {
	return "wav";
}

sub info {
	my $self = shift; $self->trace_in;

	my $info = __"Dumping WAV";
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

	my $nr   = $self->title->audio_track->tc_nr;
	
	$info .= ", ".__x("track #{nr}", nr => $nr);
	$info .= ", ".__x("chapter #{chapter}", chapter => $self->chapter)
		if defined $self->chapter;
	
	return $info;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	my $sample_rate = $self->title->audio_track->sample_rate;
	my $runtime = $self->title->runtime;
	
	return int($runtime * $sample_rate * 2 / 1024);
}

sub get_diskspace_freed {
	return 0;
}

sub command {
	my $self = shift; $self->trace_in;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);

	my $command = $self->title->get_create_wav_command;

	$title->set_actual_chapter (undef);

	return $command;
}

sub commit {
	my $self = shift;

	1;
}

1;
