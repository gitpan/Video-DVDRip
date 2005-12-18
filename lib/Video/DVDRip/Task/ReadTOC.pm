# $Id: ReadTOC.pm,v 1.1 2005/10/09 12:04:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Task::ReadTOC;

use base qw( Video::DVDRip::Task );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub cb_title_probed		{ shift->{cb_title_probed}		}
sub set_cb_title_probed		{ shift->{cb_title_probed}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($cb_title_probed) = @par{'cb_title_probed'};

	my $self = $class->SUPER::new(@_);
	
	$self->set_cb_title_probed($cb_title_probed);
	
	return $self;
}

sub configure {
	my $self = shift;

	return $self->configure_for_lsdvd
		if $self->version("lsdvd") > 0;
	
	require Video::DVDRip::Job::ProbeTitleCount;
	require Video::DVDRip::Job::Probe;

	my $project = $self->project;
	my $content = $project->content;

	$self->set_reuse_progress(1);

	my $cb_title_probed = $self->cb_title_probed;

	my $job;

	$job = Video::DVDRip::Job::ProbeTitleCount->new;
	$job->set_content ($content);
	$job->set_cb_finished ( sub {
		my $titles = $content->get_titles_by_nr;
		foreach my $title ( @{$titles} ) {
			$job  = Video::DVDRip::Job::Probe->new (
				title => $title,
			);
			$job->set_progress_max( scalar(@{$titles})+0.001 );
			$job->set_cb_finished ( sub {
				&$cb_title_probed($_[0]->title);
			}) if $cb_title_probed;
			$self->add_job ( $job );
		}
	});
	
	$self->set_cb_finished (sub{
		return if $self->cancelled;

		eval { $project->copy_ifo_files };

		if ( $@ ) {
			$self->ui->long_message_window (
				__"Failed to copy the IFO files. vobsub creation won't work properly.\n".
                                  "(Did you specify the mount point of your DVD drive in the Preferences?)\n".
                                  "The error message is:\n".
				  $self->stripped_exception
					
			);
		}

		$project->backup_copy;

		1;
	});

	
	$self->add_job( $job );

	1;	
}

sub configure_for_lsdvd {
	my $self = shift;
	
	require Video::DVDRip::Job::ReadDVDToc;

	my $project = $self->project;

	my $job;

	$job = Video::DVDRip::Job::ReadDVDToc->new;
	$job->set_project ($project);

	$self->add_job( $job );

	$self->set_cb_finished (sub{
		return if $self->cancelled;

		eval { $project->copy_ifo_files };

		if ( $@ ) {
			$self->ui->long_message_window (
				__"Failed to copy the IFO files. vobsub creation won't work properly.\n".
                                  "(Did you specify the mount point of your DVD drive in the Preferences?)\n".
                                  "The error message is:\n".
				  $self->stripped_exception
					
			);
		}

		$project->backup_copy;

		1;
	});

	1;
}

1;
