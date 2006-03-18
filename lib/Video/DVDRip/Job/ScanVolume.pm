# $Id: ScanVolume.pm,v 1.5 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::ScanVolume;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job;

use Carp;
use strict;

sub count                       { shift->{count}                        }
sub set_count                   { shift->{count}                = $_[1] }
sub chapter                     { shift->{chapter}                      }
sub set_chapter                 { shift->{chapter}              = $_[1] }

sub type {
	return "scan";
}

sub info {
	my $self = shift;

        my $chapter = $self->chapter;

	my $info = __"Volume scanning";
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

        if ( $chapter ) {
                $info .= ", ".__x("chapter #{chapter}", chapter => $chapter);
        }

	$info .= ", ".__x("audio track #{nr}", nr => $self->title->audio_channel);

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$title->set_actual_chapter ($self->chapter);

	if ( $title->project->rip_mode eq 'rip' ) {
		$self->set_progress_show_fps ( 0 );
		$self->set_progress_max ( $title->get_vob_size );

	} elsif ( not $self->chapter ) {
		$self->set_progress_show_fps ( 1 );
		$self->set_progress_max ( $title->frames );

	} else {
		if ( defined $self->chapter_frames->{$self->chapter} ) {
			$self->set_progress_show_fps ( 1 );
			$self->set_progress_max ( 
				$self->chapter_frames->{$self->chapter}
			);
		} else {
			$self->set_progress_show_fps ( 0 );
		}
	}

        $title->set_actual_chapter (undef);
	
	1;
}

sub command {
	my $self = shift;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);

        my $command = $title->get_scan_command;

        $title->set_actual_chapter (undef);

	return $command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ($line =~ /dr_progress/ ) {
		$line =~ m!(\d+)/\d+\n.*?$!;
		$self->set_progress_cnt ($1);
	} else {
		my $frames = $self->progress_cnt;
		++$frames while $line =~ /^[\d\t ]+$/gm;
		$self->set_progress_cnt ($frames);
	}

	$self->set_operation_successful (1)
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift;

	my $count = $self->count;

	$self->title->analyze_scan_output (
		output => $self->pipe->output,
		count  => $count,
	);
	
	1;
}

1;
