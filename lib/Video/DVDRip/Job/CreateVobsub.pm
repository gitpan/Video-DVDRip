# $Id: CreateVobsub.pm,v 1.5 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::CreateVobsub;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job;

use Carp;
use strict;

sub subtitle			{ shift->{subtitle}			}
sub count_job			{ shift->{count_job}			}
sub file_nr			{ shift->{file_nr}			}

sub set_subtitle		{ shift->{subtitle}		= $_[1]	}
sub set_count_job		{ shift->{count_job}		= $_[1]	}
sub set_file_nr			{ shift->{file_nr}		= $_[1]	}

sub type {
	return "create vobsub";
}

sub info {
	my $self = shift;

	my $sid = $self->subtitle->id;

	my $info = __x("Create vobsub of subtitle #{sid}, title #{title}", sid => $sid, title => $self->title->nr);
	
	$info .= ", ".__x("part #{file_nr}", file_nr => $self->file_nr)
		if defined $self->file_nr;

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$self->set_progress_show_fps ( 0 );
	$self->set_progress_max ( 10000 );
	
	1;
}

sub command {
	my $self = shift;

	if ( not $self->count_job ) {
		# no splitting
		return $self->title->get_create_vobsub_command (
			subtitle => $self->subtitle
		);
	}

	# with splitting
	my $file_nr = $self->file_nr;

	my ($start, $end);
	if ( $file_nr == 0 ) {
		$start = 0;
		$end   = $self->count_job->files_scanned->[$file_nr]->{frames}/
			      $self->title->tc_video_framerate;
	} else {
		$start = $self->count_job->files_scanned->[$file_nr-1]->{end};
		$end   = $start + 
			 $self->count_job->files_scanned->[$file_nr]->{frames}/
			      $self->title->tc_video_framerate;
		$end += 1000 if $file_nr ==
				@{$self->count_job->files_scanned} - 1;
	}

	$self->count_job->files_scanned->[$file_nr]->{end} = $end;

	return $self->title->get_create_vobsub_command (
		subtitle => $self->subtitle,
		start    => $start,
		end      => $end,
		file_nr  => $file_nr,
	);
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ($line =~ /dr_progress/ ) {
		$line =~ m!(\d+)/(\d+)\n.*?$!;
		$self->set_progress_cnt (10000*$1/$2);
	}

	$self->set_operation_successful (1)
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
