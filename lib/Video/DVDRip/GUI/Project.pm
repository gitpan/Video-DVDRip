# $Id: Project.pm,v 1.15 2001/12/15 00:16:23 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
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
use Video::DVDRip::GUI::Project::ClipZoomTab;
use Video::DVDRip::GUI::Project::TranscodeTab;
use Video::DVDRip::GUI::Project::LoggingTab;

use Carp;
use strict;

sub project			{ shift->{project}			}
sub set_project			{ shift->{project}		= $_[1] }

sub selected_title		{ shift->{selected_title}		}
sub set_selected_title		{ shift->{selected_title}	= $_[1] }

sub gtk_title_labels		{ shift->{gtk_title_labels}		}	# lref
sub set_gtk_title_labels	{ shift->{gtk_title_labels}	= $_[1] }

sub logger			{ shift->{logger}			}
sub set_logger			{ shift->{logger}		= $_[1] }

sub closed			{ shift->{closed}			}
sub set_closed			{ shift->{closed}		= $_[1] }

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
	$notebook->set_usize (undef, 100);
	$notebook->set_homogeneous_tabs(1);
	$notebook->show;
	
	$self->set_gtk_title_labels([]);
	$self->set_adjust_widgets({});
	$self->set_transcode_widgets({});

	my $label;

	$label = Gtk::Label->new ("Storage");
	$notebook->append_page ($self->create_storage_tab, $label);

	$label = Gtk::Label->new ("RIP Title");
	$notebook->append_page ($self->create_title_tab, $label);

	$label = Gtk::Label->new ("  Clip & Zoom  ");
	$notebook->append_page ($self->create_adjust_tab, $label);

	$label = Gtk::Label->new ("Transcode");
	$notebook->append_page ($self->create_transcode_tab, $label);

	$label = Gtk::Label->new ("Logging");
	$notebook->append_page ($self->create_logging_tab, $label);

	$vbox->pack_start ($notebook, 1, 1, 0);

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
	my $self = shift;

	$self->init_title_labels;
	$self->init_audio_popup;
	$self->init_adjust_values;
	$self->init_transcode_values;

	1;
}

sub close {
	my $self = shift;
	return if $self->closed;

	$self->log ("Project closed.");
	$self->set_closed(1);
	
	1;
}

sub log {
	my $self = shift;
	$self->logger->log (@_);
	1;
}

1;
