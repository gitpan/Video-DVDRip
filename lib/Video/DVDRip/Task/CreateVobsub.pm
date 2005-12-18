# $Id: CreateVobsub.pm,v 1.1 2005/10/09 12:04:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Task::CreateVobsub;

use base qw( Video::DVDRip::Task );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

use Video::DVDRip::Job::CreateVobsub;
use Video::DVDRip::Job::CountFramesInFile;
use Video::DVDRip::Job::ExtractPS1;

sub subtitle			{ shift->{subtitle}			}
sub set_subtitle		{ shift->{subtitle}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($subtitle) = @par{'subtitle'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_subtitle($subtitle);
	
	return $self;
}

sub configure {
	my $self = shift;

	my $title = $self->project->content->selected_title;

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		if ( not -f $subtitle->ifo_file ) {
			$self->ui->message_window (
			    message =>
				__"Need IFO files in place.\n".
				  "You must re-read TOC from DVD."
			);
			$self->set_configure_failed(1);
			return 1;
		}
	}


	my $split = $title->tc_split;

	return $self->configure_non_splitted_vobsub unless $split;

	my $files = $title->get_split_files;

	if ( @{$files} == 0 ) {
		$self->ui->message_window (
		    message =>
			__"No splitted target files available.\n".
			  "First transcode and split the movie."
		);
		$self->set_configure_failed(1);
		return 1;
	}

	my $job = Video::DVDRip::Job::CountFramesInFile->new (
		title => $title,
	);
	
	my $count_job = my $last_job = $self->add_job ( $job );

	my @subtitles;
	if ( $self->subtitle ) {
		@subtitles = ( $self->subtitle );
	} else {
		@subtitles = sort { $a->id <=> $b->id }
			     values %{$title->subtitles};
	}

	foreach my $subtitle ( @subtitles ) {
		next if !$subtitle->tc_vobsub && !$self->subtitle;
		$job  = Video::DVDRip::Job::ExtractPS1->new (
			title => $title,
		);
		$job->set_subtitle ( $subtitle );
		$job->set_depends_on_jobs ( [ $last_job ] );

		$last_job = $self->add_job ( $job );

		my $file_nr = 0;
		foreach my $file ( @{$files} ) {
			$job = Video::DVDRip::Job::CreateVobsub->new (
				title => $title,
			);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$job->set_subtitle ( $subtitle );
			$job->set_count_job ( $count_job );
			$job->set_file_nr ( $file_nr );
	
			$last_job = $self->add_job ( $job );
			++$file_nr;
		}
	}

	1;
}

sub configure_non_splitted_vobsub {
	my $self = shift;

	my $title = $self->project->content->selected_title;
	
	my @subtitles;
	if ( $self->subtitle ) {
		@subtitles = ( $self->subtitle );
	} else {
		@subtitles = sort { $a->id <=> $b->id }
			     values %{$title->subtitles};
	}

	my $job;
	my $last_job;
	foreach my $subtitle ( @subtitles ) {
		next if !$subtitle->tc_vobsub && !$self->subtitle;
		$job  = Video::DVDRip::Job::ExtractPS1->new (
			title => $title,
		);

		$job->set_subtitle ( $subtitle );
		$job->set_depends_on_jobs ( [ $last_job ] ) if $last_job;

		$last_job = $self->add_job ( $job );

		$job  = Video::DVDRip::Job::CreateVobsub->new (
			title => $title,
		);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$job->set_subtitle ( $subtitle );
	
		$last_job = $self->add_job ( $job );
	}

	1;
}

1;
