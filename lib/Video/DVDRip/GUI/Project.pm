# $Id: Project.pm,v 1.27.2.1 2002/12/02 18:22:38 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

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

	$label = Gtk::Label->new ("Storage");
	$notebook->append_page ($storage_tab, $label);

	$label = Gtk::Label->new ("RIP Title");
	$notebook->append_page ($title_tab, $label);

	$label = Gtk::Label->new (" Clip & Zoom ");
	$notebook->append_page ($adjust_tab, $label);

	$label = Gtk::Label->new ("Subtitles");
	$notebook->append_page ($subtitle_tab, $label);

	$label = Gtk::Label->new ("Transcode");
	$notebook->append_page ($transcode_tab, $label);

	$label = Gtk::Label->new ("Burn");
	$notebook->append_page ($burn_tab, $label);

	$label = Gtk::Label->new ("Logging");
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
		$self->log ("Open project from file '".$self->project->filename."'");
	} else {
		$self->log ("Create new project.");
	}

	return $vbox;
}

sub fill_with_values {
	my $self = shift; $self->trace_in;

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

	1;
}

sub close {
	my $self = shift;
	return if $self->closed;

	$self->log ("Project closed.");
	$self->set_closed(1);
	
	1;
}

1;
