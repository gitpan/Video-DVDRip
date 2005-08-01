# $Id: Title.pm,v 1.2 2005/08/01 19:18:22 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Title;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

use File::Path;

sub build_factory {
	my $self = shift;

	my $context = $self->get_context;

	return Gtk2::Ex::FormFactory::VBox->new (
	    title 	     => __"RIP Title",
	    object           => "project",
	    active_cond      => sub { $self->project &&
	    			      $self->project->created },
	    active_depends   => "project.created",
	    no_frame         => 1,
	    content 	     => [
	    	Gtk2::Ex::FormFactory::HBox->new (
		    name        => "dvd_toc_buttons",
		    title 	=> __"Read content",
		    content 	=> [
	    		Gtk2::Ex::FormFactory::Button->new (
			    object	 => "project",
			    label	 => __"Read DVD table of contents",
			    tip		 => __"Scan the DVD for all available titles ".
			    		      "and setup the table of contents",
			    stock        => "gtk-find",
			    clicked_hook => sub { $self->ask_read_dvd_toc },
			),
	    		Gtk2::Ex::FormFactory::Button->new (
			    object	 => "project",
			    label	 => __"Open DVD tray",
			    tip		 => __"Open the tray of your configuried DVD device",
			    stock        => "gtk-open",
			    clicked_hook => sub { $self->eject_dvd },
			),
	    		Gtk2::Ex::FormFactory::Button->new (
			    object	 => "project",
			    label	 => __"Close DVD tray",
			    tip		 => __"Close the tray of your configuried DVD device",
			    stock        => "gtk-close",
			    clicked_hook => sub { $self->insert_dvd },
			),
		    ]
		),
	    	Gtk2::Ex::FormFactory::VBox->new (
		    title   => __"DVD table of contents",
		    expand  => 1,
		    object  => "content",
		    content => [
	    		Gtk2::Ex::FormFactory::HBox->new (
	  	            expand => 1,
			    content => [
				Gtk2::Ex::FormFactory::List->new (
				      name           => "content_list",
				      attr           => "content.titles",
				      attr_select    => "content.selected_titles",
				      attr_select_column => 0,
				      tip            => "Select title for further operation",
				      expand         => 1,
				      scrollbars     => [ "never", "automatic" ],
				      columns        => [
				          "idx",
				      	  __"Title", __"Runtime", __"Norm",
			      		  __"Chp", __"Audio",
					  __"Framerate", __"Aspect", 
					  __"Frames", __"Resolution"
				      ],
				      selection_mode   => "multiple",
				      customize_hook => sub {
	        			  my ($gtk_simple_list) = @_;
					  ($gtk_simple_list->get_columns)[0]->set ( visible => 0 );
					  1;
				      },
				),
				$self->build_audio_viewing_chapter_factory,
			    ]
			),
			Gtk2::Ex::FormFactory::HBox->new (
			    object  => "title",
			    content => [
		    		Gtk2::Ex::FormFactory::Button->new (
				    label => __"View selected title/chapter(s)",
				    stock => "gtk-media-play",
				    clicked_hook => sub { $self->view_title },
				),
		    		Gtk2::Ex::FormFactory::Button->new (
				    label => __"RIP selected title(s)/chapter(s)",
				    stock => "gtk-harddisk",
				    clicked_hook => sub { $self->rip_title },
				    active_cond  => sub {
				        return 1 unless $self->project;
					$self->project->rip_mode eq 'rip';
				    },
				    active_depends => "project.rip_mode",
				),

			    ],
			),
		    ],
		),
	    ],
	);
}

sub build_audio_viewing_chapter_factory {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::VBox->new (
	    object  => "title",
	    content => [
		Gtk2::Ex::FormFactory::Popup->new (
		    name  => "audio_selection",	# Title->audio_channel_list requires this
		    attr  => "title.audio_channel",
		    label => __"Select audio track",
		    tip   => __"All audio tracks are ripped, but this ".
			       "track is also scanned for volume while ".
			       "ripping",
		),
		Gtk2::Ex::FormFactory::Popup->new (
		    attr  => "title.tc_viewing_angle",
		    label => __"Select viewing angle",
		    tip   => __"This selection affects ripping, so you ".
			       "must rip again if you change this later",
		),
		Gtk2::Ex::FormFactory::HBox->new (
		    object  => "title",
		    label   => __"Specify chapter mode",
		    content => [
		        Gtk2::Ex::FormFactory::RadioButton->new (
			    attr  => "title.tc_use_chapter_mode",
			    value => "0",
			    label => __"No",
			    tip   => __"The title is handled as a whole ".
			    	       "ignoring all chapter marks",
			),
		        Gtk2::Ex::FormFactory::RadioButton->new (
			    attr  => "title.tc_use_chapter_mode",
			    value => "all",
			    label => __"All",
			    tip   => __"Processing is divided into ".
			    	       "chapters. You get one file per ".
				       "chapter for all chapters of this title",
			),
		        Gtk2::Ex::FormFactory::RadioButton->new (
			    attr  => "title.tc_use_chapter_mode",
			    value => "select",
			    label => __"Selection",
			    tip   => __"Processing is divided into ".
			    	       "chapters. You get one file per ".
				       "chapter for a specific selection ".
			    	       "of chapters",
			),
		    ],
		),
		Gtk2::Ex::FormFactory::List->new (
		    name	   => "chapter_selection",
		    attr           => "title.chapter_list",
		    attr_select    => "title.tc_selected_chapters",
		    expand	   => 1,
		    scrollbars     => [ "never", "always" ],
		    tip            => __"Select one or more chapters",
		    columns        => [ __"Chapter Selection" ],
		    selection_mode => "multiple",
		    inactive       => "invisible",
		),
	    ],
	);
}

sub ask_read_dvd_toc {
	my $self = shift; $self->trace_in;

	if ( $self->project->content->titles ) {
		$self->get_form_factory->open_confirm_window (
			message =>
				__"If you re-read the TOC, all settings in\n".
                                  "this project get lost. Probably you want\n".
                                  "to save the project to another file before\n".
                                  "you proceeed.\n\n".
                                  "Do you want to re-read the TOC now?",
			yes_callback => sub { $self->read_dvd_toc },
			yes_label => __"Yes",
			
		);
	} else {
		return $self->read_dvd_toc;
	}
}

sub read_dvd_toc {
	my $self = shift; $self->trace_in;

	return if $self->progress_is_active;

	# good time creating the tmp dir (for the logfile);
	mkpath ( [ $self->project->snap_dir ], 0, 0755);

	my $project = $self->project;
	my $content = $project->content;

	$self->clear_content_list;

	$self->get_context->set_object("title", undef);

	my $nr;
	my $job;
	my $exec = $self->new_job_executor (
		reuse_progress => 1
	);

	$job  = Video::DVDRip::Job::ProbeTitleCount->new (
		nr    => ++$nr,
	);
	$job->set_content ($content);

	$job->set_cb_finished ( sub {
		my $titles = $content->get_titles_by_nr;
		foreach my $title ( @{$titles} ) {
			$job  = Video::DVDRip::Job::Probe->new (
				nr    => ++$nr,
				title => $title,
			);

			$job->set_progress_max(scalar(@{$titles})+0.001);

			$job->set_cb_finished (sub {
				$self->append_content_list ( title => $title );
			});

			$exec->add_job ( job => $job );
		}
	});
	
	$exec->set_cb_finished (sub{
		return if $exec->cancelled;

		eval { $self->project->copy_ifo_files };

		if ( $@ ) {
			$self->long_message_window (
				message =>
					__"Failed to copy the IFO files. vobsub creation won't work properly.\n".
                                         "(Did you specify the mount point of your DVD drive in the Preferences?)\n".
                                         "The error message is:\n".
					$self->stripped_exception
					
			);
		}
		$self->project->backup_copy;

		1;
	});

	
	$exec->add_job ( job => $job );
	$exec->execute_jobs;

	1;
}

sub clear_content_list {
	my $self = shift; $self->trace_in;

	my $content = $self->project->content;

	$content->set_titles({});
	$content->set_selected_titles([]);
	
	$self->get_context->update_object_widgets("content");
	$self->get_context->update_object_widgets("title");

	1;
}

sub append_content_list {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($title) = @par{'title'};

	my $list = $self->get_form_factory->get_widget("content_list");

	push @{$list->get_gtk_widget->{data}}, [
		($title->nr-1),
		$title->nr, $self->format_time( time => $title->runtime ),
		uc($title->video_mode), $title->chapters,
		scalar(@{$title->audio_tracks}),
		$title->frame_rate, $title->aspect_ratio, $title->frames,
		$title->width."x".$title->height
	];
	
	1;
}

sub rip_title_selection_sensitive {
	my $self = shift;
	my ($active) = @_;

	my $state = $active ? "active" : "inactive";

	my $context      = $self->get_context;
	my $form_factory = $self->get_form_factory;

	my $toc_buttons = $form_factory->get_widget ("dvd_toc_buttons");
	my $chapter_sel = $form_factory->get_widget ("chapter_selection");

	#-- All widgets of the 'title' and 'content' objects
	$context->update_object_widgets_activity ("title", $state);
	$context->update_object_widgets_activity ("content", $state);

	#-- Chapter needs to be updated separatly, since they depend
	#-- on the title (chapter mode active) but FormFactory's
	#-- automatism doesn't work here, since update_object_widgets_activity()
	#-- overrides it with the given $state.
	$chapter_sel->update() if $state eq 'active';

	#-- And finally the TOC buttons
	$toc_buttons->update_widget_activity($state);

	1;
}

sub rip_title {
	my $self = shift; $self->trace_in;

	$self->rip_title_selection_sensitive(0);

	my $context = $self->get_context;
	my $content = $context->get_object("content");

	my $selected_title_idx = $content->selected_titles;

	my $nr;
	my $job;
	my $last_job;
	my $exec = $self->new_job_executor;

	foreach my $title_idx ( @{$selected_title_idx} ) {
		my $title = $content->titles->{$title_idx+1};
		if ( not $title->tc_use_chapter_mode ) {
		    my $job = Video::DVDRip::Job::Rip->new (
			nr    => ++$nr,
			title => $title,
		    );
		    $last_job = $exec->add_job ( job => $job );

		} else {
		    foreach my $chapter ( @{$title->get_chapters} ) {
			$job = Video::DVDRip::Job::Rip->new (
			    nr    => ++$nr,
			    title => $title,
			);
			$job->set_chapter ( $chapter );
			$last_job = $exec->add_job ( job => $job );
		    }
		}
	}

	$exec->set_cb_finished (sub {
		$self->rip_title_selection_sensitive(1);
		if ( $exec->cancelled ) {
			$exec->cancelled_job->title->remove_vob_files
				if $exec->cancelled_job;

		} elsif ( ! $exec->errors_occured ) {
			$context->update_object_widgets("audio_track");
			$self->get_context_object("clip_zoom")
			     ->grab_preview_frame;
			$self->project->backup_copy;
		}
		1;
	});

	$exec->execute_jobs (
		max_diskspace_needed => 6 * 1024
	);

	1;
}

sub view_title {
	my $self = shift;

	my $title = $self->selected_title;

	if ( not $title ) {
		$self->message_window (
			message => __"Please select a title."
		);
		return;
	}

	if ( $title->tc_use_chapter_mode eq 'select' ) {
		my $chapters = $title->tc_selected_chapters;
		if ( not $chapters or not @{$chapters} ) {
			$self->message_window (
				message => __"No chapters selected."
			);
			return;
		}
	}
	
	my $command = $title->get_view_dvd_command (
		command_tmpl => $self->config('play_dvd_command')
	);

	$self->log ("Executing view command: $command");

	system ($command." &");
	
	1;
}

sub eject_dvd {
        my $self = shift;

        my $command = $self->config('eject_command') . " " . $self->config('dvd_device');

        system ("$command &");
        
        1;
}

sub insert_dvd {
        my $self = shift;

        my $command = $self->config('eject_command') . " -t " . $self->config('dvd_device');

         system ("$command &");
        
        1;
}


1;
