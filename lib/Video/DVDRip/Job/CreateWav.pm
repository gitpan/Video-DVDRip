# $Id: CreateWav.pm,v 1.4 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::CreateWav;

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

	my $info = "Dumping WAV - title #".$self->title->nr;
	my $nr   = $self->title->audio_track->tc_nr;
	
	$info .= ", track #$nr";
	$info .= ", chapter #".
		 $self->chapter if defined $self->chapter;
	
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