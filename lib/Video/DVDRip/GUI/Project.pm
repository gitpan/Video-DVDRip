# $Id: Project.pm,v 1.33 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Component;

use Video::DVDRip::GUI::ImageClip;
use Video::DVDRip::GUI::Progress;

# These are not classes. they define methods inside
# the Video::DVDRip::GUI::Project package. This is only for
# splitting this huge package into handy pieces.

use Video::DVDRip::GUI::Project::StorageTab;
use Video::DVDRip::GUI::Project::TitleTab;
use Video::DVDRip::GUI::Project::SubtitleTab;
use Video::DVDRip::GUI::Project::ClipZoomTab;
use Video::DVDRip::GUI::Project::TranscodeTab;
use Video::DVDRip::GUI::Project::BurnTab;
use Video::DVDRip::GUI::Project::LoggingTab;

use Video::DVDRip::GUI::ExecuteJobs;

use Carp;
use strict;

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1] }

sub selected_title		{ shift->{selected_title}		}
sub set_selected_title		{ shift->{selected_title}	= $_[1] }

sub gtk_title_labels		{ shift->{gtk_title_labels}		}	# lref
sub set_gtk_title_labels	{ shift->{gtk_title_labels}	= $_[1] }

sub gtk_notebook		{ shift->{gtk_notebook}			}
sub set_gtk_notebook		{ shift->{gtk_notebook}		= $_[1]	}

sub closed			{ shift->{closed}			}
sub set_closed			{ shift->{closed}		= $_[1] }

sub set_text_norm_style		{ shift->{text_norm_style}	= $_[1] }
sub text_norm_style		{ shift->{text_norm_style}		}

sub set_text_warn_style		{ shift->{text_warn_style}	= $_[1] }
sub text_warn_style		{ shift->{text_warn_style}		}

sub gtk_tabs			{ shift->{gtk_tabs}			}
sub set_gtk_tabs		{ shift->{gtk_tabs}		= $_[1]	}


#------------------------------------------------------------------------
# Build Project GUI
#------------------------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;

	my $notebook = Gtk::Notebook->new;
	$notebook->set_tab_pos ('top');
	$notebook->set_homogeneous_tabs(1);
	$notebook->show;

	$self->set_gtk_notebook($notebook);

	$self->set_gtk_title_labels([]);
	$self->set_adjust_widgets({});
	$self->set_transcode_widgets({});

	my $norm_style = $vbox->style->copy;
	$self->set_text_norm_style ($norm_style);
	
	my $warn_style = $vbox->style->copy;
	$warn_style->fg('normal',$self->gdk_color('ff0000'));
	$self->set_text_warn_style ($warn_style);

	my $label;

	my $burn_tab      = $self->create_burn_tab;
	my $subtitle_tab  = $self->create_subtitle_tab;
	my $transcode_tab = $self->create_transcode_tab;
	my $storage_tab   = $self->create_storage_tab;
	my $adjust_tab    = $self->create_adjust_tab;
	my $logging_tab   = $self->create_logging_tab;
	my $title_tab     = $self->create_title_tab;

	$self->set_gtk_tabs({});

	$self->gtk_tabs->{burn}      = $burn_tab;
	$self->gtk_tabs->{subtitle}  = $subtitle_tab;
	$self->gtk_tabs->{transcode} = $transcode_tab;
	$self->gtk_tabs->{storage}   = $storage_tab;
	$self->gtk_tabs->{adjust}    = $adjust_tab;
	$self->gtk_tabs->{logging}   = $logging_tab;
	$self->gtk_tabs->{title}     = $title_tab;

	$label = Gtk::Label->new (__"Storage");
	$notebook->append_page ($storage_tab, $label);

	$label = Gtk::Label->new (__"RIP Title");
	$notebook->append_page ($title_tab, $label);

	$label = Gtk::Label->new (__"Clip & Zoom");
	$notebook->append_page ($adjust_tab, $label);

	$label = Gtk::Label->new (__"Subtitles");
	$notebook->append_page ($subtitle_tab, $label);

	$label = Gtk::Label->new (__"Transcode");
	$notebook->append_page ($transcode_tab, $label);

	$label = Gtk::Label->new (__"Burn");
	$notebook->append_page ($burn_tab, $label);

	$label = Gtk::Label->new (__"Logging");
	$notebook->append_page ($logging_tab, $label);

	$vbox->pack_start ($notebook, 1, 1, 0);

	$notebook->signal_connect ("switch-page", sub {
		my ($nb_wid,$pag_wid,$page_nr) = @_;
		$self->init_burn_files if $page_nr == 5;
		$self->comp('progress')->set_idle_label if $page_nr == 1;
		1;
	} );

	my $frame = Gtk::Frame->new ("Status");
	$frame->show;
	$vbox->pack_start ($frame, 0, 1, 0);

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;
	$frame->add($hbox);

	my $progress = Video::DVDRip::GUI::Progress->new;
	$progress->build;

	$hbox->pack_start($progress->widget,1,1,0);

	$self->set_widget($vbox);
	$self->set_comp ( project => $self );

	if ( $self->project->filename ) {
		$self->log (__x("Open project from file '{filename}'", filename => $self->project->filename));
	} else {
		$self->log (__"Create new project.");
	}

	return $vbox;
}

sub fill_with_values {
	my $self = shift; $self->trace_in;

	if ( $self->project->content->titles ) {
		$self->set_selected_title(
			$self->project->content->titles->{$self->project->selected_title_nr}
		);
		$self->init_title_labels;
		$self->init_audio_popup;
		$self->init_chapter_list;
		$self->init_transcode_values;
		$self->init_storage_values;
		$self->init_burn_values;
		$self->init_subtitle_values;
		$self->init_adjust_values;
	}

	if ( not $self->selected_title ) {
		$self->gtk_tabs->{burn}->set_sensitive(0);
		$self->gtk_tabs->{subtitle}->set_sensitive(0);
		$self->gtk_tabs->{transcode}->set_sensitive(0);
		$self->gtk_tabs->{adjust}->set_sensitive(0);
	} elsif ( $self->gtk_tabs ) {
		$self->gtk_tabs->{burn}->set_sensitive(1);
		$self->gtk_tabs->{subtitle}->set_sensitive(1);
		$self->gtk_tabs->{transcode}->set_sensitive(1);
		$self->gtk_tabs->{adjust}->set_sensitive(1);
	}

	1;
}

sub close {
	my $self = shift;
	return if $self->closed;

	$self->log (__"Project closed.");
	$self->set_closed(1);
	
	1;
}

sub open_visual_frame_range {
	my $self = shift;
	
	require Video::DVDRip::GUI::VisualFrameRange;
	
	my $visual_frame_range = Video::DVDRip::GUI::VisualFrameRange->new;
	$visual_frame_range->build;
	
	1;
}

1;
