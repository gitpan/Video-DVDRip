# $Id: StorageTab.pm,v 1.14 2002/11/03 11:36:59 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

sub storage_widgets		{ shift->{storage_widgets}		}
sub set_storage_widgets		{ shift->{storage_widgets}	= $_[1]	}

sub in_storage_init		{ shift->{in_storage_init}		}
sub set_in_storage_init		{ shift->{in_storage_init}	= $_[1]	}

#------------------------------------------------------------------------
# Build Storage Tab
#------------------------------------------------------------------------

sub create_storage_tab {
	my $self = shift; $self->trace_in;

	$self->set_storage_widgets({});

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	my $storage_frame = $self->create_storage_frame;
	my $source_frame  = $self->create_source_frame;
	
	$vbox->pack_start ( $storage_frame, 0, 1, 0);
	$vbox->pack_start ( $source_frame, 0, 1, 0);
	
	return $vbox;
}

sub create_storage_frame {
	my $self = shift; $self->trace_in;
	
	my $frame = Gtk::Frame->new ("Storage path information");
	$frame->show;

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	my ($dialog, $widgets) = $self->create_dialog (
		{ label => "Project name",
		  value => $self->project->name,
		  type  => 'text'
		},
		{ label => "VOB directory",
		  value => $self->project->vob_dir,
		  type  => 'text',
		  onchange => sub {
		  	my $text = $_[0]->get_text;
			if ( not $text =~ m!^/! ) {
				$text = "/$text";
				$_[0]->set_text($text);
			}
		  	$self->project->set_vob_dir ($text)
		  },
		},
		{ label => "AVI directory",
		  value => $self->project->avi_dir,
		  type  => 'text',
		  onchange => sub {
		  	my $text = $_[0]->get_text;
			if ( not $text =~ m!^/! ) {
				$text = "/$text";
				$_[0]->set_text($text);
			}
		  	$self->project->set_avi_dir ($text)
		  },
		},
		{ label => "Temporary directory",
		  value => $self->project->snap_dir,
		  type  => 'text',
		  onchange => sub {
		  	my $text = $_[0]->get_text;
			if ( not $text =~ m!^/! ) {
				$text = "/$text";
				$_[0]->set_text($text);
			}
		  	$self->project->set_snap_dir ($text)
		  },
		},
	);

	# changes of project name should also change
	# vob- and avi-dir, if they are not touched yet
	$widgets->[0]->signal_connect ("changed", sub {
		if ( $widgets->[0]->get_text =~ /\s/ ) {
			# spaces in project name not allowed
			$widgets->[0]->set_text ( $self->project->name );
			return 1;
		}
		if ( $widgets->[1]->get_text eq
		     $self->config('base_project_dir')."/".
		     $self->project->name."/vob" ) {
			$self->project->set_vob_dir (
				$self->config('base_project_dir')."/".
				$widgets->[0]->get_text."/vob"
			);
			$widgets->[1]->set_text ( $self->project->vob_dir );
		}
		if ( $widgets->[2]->get_text eq
		     $self->config('base_project_dir')."/".
		     $self->project->name."/avi" ) {
			$self->project->set_avi_dir (
				$self->config('base_project_dir')."/".
				$widgets->[0]->get_text."/avi"
			);
			$widgets->[2]->set_text ( $self->project->avi_dir );
		}
		if ( $widgets->[3]->get_text eq
		     $self->config('base_project_dir')."/".
		     $self->project->name."/tmp" ) {
			$self->project->set_snap_dir (
				$self->config('base_project_dir')."/".
				$widgets->[0]->get_text."/tmp"
			);
			$widgets->[3]->set_text ( $self->project->snap_dir );
		}
		$self->project->set_name ($widgets->[0]->get_text);
		$self->comp('main')->widget->set_title (
			$self->config('program_name')." - ".$self->project->name
		);
	});

	$hbox->pack_start ( $dialog, 0, 1, 0);
	$frame->add ($hbox);

	return $frame;
}

sub create_source_frame {
	my $self = shift; $self->trace_in;
	
	my $frame = Gtk::Frame->new ("Data source mode selection");
	$frame->show;

	my $frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	my ($table, $hbox, $vbox, $row, $radio, $radio_group, $label, $entry);

	# Table
	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 2 );
	$table->set_col_spacings ( 7 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Mode 1 - rip data to hd
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$radio = $radio_group = Gtk::RadioButton->new;
	$radio->show;
	$hbox->pack_start($radio, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$label = Gtk::Label->new ("Rip data from DVD to harddisk before encoding");
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->storage_widgets->{rip_mode_rip} = $radio;

	# Warning message
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new (
		"\n".
		"Use the following modes only, if ripping is no option for you.\n".
		"Many interesting features are disabled for them."
	);
	$label->set_justify('left');
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 2, $row, $row+1, 'fill','expand',0,0);


	# Mode 2 - transcode on the fly from dvd
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$radio = $radio_group = Gtk::RadioButton->new ("", $radio_group);
	$radio->show;
	$hbox->pack_start($radio, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$label = Gtk::Label->new ("Encode DVD on the fly");
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);
	
	$self->storage_widgets->{rip_mode_dvd} = $radio;

	# Mode 3 - Use existent DVD image on harddisk
	++$row;
	$radio = $radio_group = Gtk::RadioButton->new ("", $radio_group);
	$radio->show;
	$table->attach ($radio, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$label = Gtk::Label->new ("Use existent DVD image located in this directory:");
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start($label, 0, 1, 0);

	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	++$row;

	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_sensitive(0);

	$table->attach ($entry, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->storage_widgets->{rip_mode_dvd_image} = $radio;
	$self->storage_widgets->{rip_mode_dvd_image_dir} = $entry;

	# Connect Signals
	my $widgets = $self->storage_widgets;
	foreach my $mode ( qw ( rip dvd dvd_image ) ) {
		$widgets->{"rip_mode_$mode"}->signal_connect ("clicked", sub {
			return 1 if $self->in_storage_init;
			$self->change_rip_mode ( mode => $mode );
		} );
	}
	
	$widgets->{rip_mode_dvd_image_dir}->signal_connect ("focus-out-event", sub {
		return 1 if $self->in_storage_init;
	  	my $text = $_[0]->get_text;
		if ( not $text =~ m!^/! ) {
			$text = "/$text";
			$_[0]->set_text($text);
		}
		$self->project->set_dvd_image_dir ( $text );
		1;
	} );

	return $frame;
}

sub init_storage_values {
	my $self = shift; $self->trace_in;

	$self->set_in_storage_init(1);
	
	my $project = $self->project;

	my $widgets = $self->storage_widgets;
	$widgets->{rip_mode_dvd_image_dir}->set_text ($project->dvd_image_dir);

	my $mode = $project->rip_mode || "rip";

	$self->set_in_storage_init(0);

	$widgets->{"rip_mode_$mode"}->set_active(1);

	1;
}

sub change_rip_mode {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($mode) = @par{'mode'};

	$self->project->set_rip_mode ($mode);
	
	my $widgets = $self->storage_widgets;
	$widgets->{rip_mode_dvd_image_dir}->set_sensitive ($mode eq 'dvd_image');
	
	return 1 if not $self->transcode_widgets->{tc_psu_core_yes};

	if ( $mode ne 'rip' ) {
		$self->rip_title_widgets->{rip_button}->set_sensitive(0);
	} else {
		$self->rip_title_widgets->{rip_button}->set_sensitive(1);
	}

	$self->set_render_vobsub_sensitive;
	
	1;
}

1;
