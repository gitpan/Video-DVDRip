# $Id: TranscodeTab.pm,v 1.36 2002/03/29 16:18:28 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

sub transcode_widgets		{ shift->{transcode_widgets}		}	# href
sub set_transcode_widgets	{ shift->{transcode_widgets}	= $_[1] }

sub in_transcode_init		{ shift->{in_transcode_init}		}	# href
sub set_in_transcode_init	{ shift->{in_transcode_init}	= $_[1] }

#---------------------------------------------------------------------
# Build Transcode Tab
#---------------------------------------------------------------------

sub create_transcode_tab {
	my $self = shift; $self->trace_in;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	my $selected_title = $self->create_selected_title;
	$vbox->pack_start ( $selected_title, 0, 1, 0);

	my ($frame_hbox, $frame, $label, $entry, $hbox, $table,
	    $button, $popup_menu, $popup, $item, %popup_entries,
	    $storage_hbox, $checkbox);

	$frame = Gtk::Frame->new ("Adjust Transcode Options");
	$frame->show;
	$vbox->pack_start ( $frame, 0, 1, 0);

	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Left Table -------------------------------------------------

	$table = Gtk::Table->new ( 5, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 10 );
	$table->set_col_spacings ( 10 );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Video Codec
	my $row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Codec");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_codec} = $entry;

	# Audio Codec
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("af6 Video Codec");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_af6_codec} = $entry;

	# Enable DivX Multipass Encoding
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("DivX Multipass");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $radio_yes = Gtk::RadioButton->new ("Yes");
	$radio_yes->show;
	$hbox->pack_start($radio_yes, 0, 1, 0);
	my $radio_no = Gtk::RadioButton->new ("No", $radio_yes);
	$radio_no->show;
	$hbox->pack_start($radio_no, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_multipass_yes} = $radio_yes;
	$self->transcode_widgets->{tc_multipass_no}  = $radio_no;
	
	# Video Framerate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Framerate (fps)");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_framerate} = $entry;

	# Video Bitrate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Bitrate (kBit/s)");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_bitrate} = $entry;

	# Audio Bitrate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Audio Bitrate (kBit/s)");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_audio_bitrate} = $entry;

	# AC3 Audio Passthrough?
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("AC3 Passthrough");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$self->transcode_widgets->{tc_ac3_passthrough_hbox1} = $hbox;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $radio_yes = Gtk::RadioButton->new ("Yes");
	$radio_yes->show;
	$hbox->pack_start($radio_yes, 0, 1, 0);
	my $radio_no = Gtk::RadioButton->new ("No", $radio_yes);
	$radio_no->show;
	$hbox->pack_start($radio_no, 0, 1, 0);

	$self->transcode_widgets->{tc_ac3_passthrough_hbox2} = $hbox;
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_ac3_passthrough_yes} = $radio_yes;
	$self->transcode_widgets->{tc_ac3_passthrough_no}  = $radio_no;
	
	# Separator

	my $sep = Gtk::VSeparator->new;
	$sep->set_usize(40,undef);
	$sep->show;
	$frame_hbox->pack_start ($sep, 0, 1, 0);
	
	# Right Table ------------------------------------------------
	
	$table = Gtk::Table->new ( 5, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 10 );
	$table->set_col_spacings ( 10 );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Deinterlace
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Deinterlace Mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize(220,undef);

	%popup_entries = (
		0 => "No Deinterlacing",
		1 => "1 - Interpolate Scanlines (fast)",
		2 => "2 - Handled By Encoder (may segfault)",
		3 => "3 - Zoom To Full Frame (slow)",
	);
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				return 1 if not $self->selected_title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_deinterlace($key)
			}, $key
		);
	}
	$table->attach_defaults ($popup, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_deinterlace_popup} = $popup;

	# Antialias
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Antialias Mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize(220,undef);

	%popup_entries = (
		0 => "No Antialiasing",
		1 => "1 - Process De-Interlace Effects",
		2 => "2 - Process Resize Effects",
		3 => "3 - Process Full Frame (slow)",
	);
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				return 1 if not $self->selected_title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_anti_alias($key)
			}, $key
		);
	}
	$table->attach_defaults ($popup, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_anti_alias_popup} = $popup;

	# Use YUV Internal
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Use YUV Internal");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $radio_yes = Gtk::RadioButton->new ("Yes");
	$radio_yes->show;
	$hbox->pack_start($radio_yes, 0, 1, 0);
	my $radio_no = Gtk::RadioButton->new ("No", $radio_yes);
	$radio_no->show;
	$hbox->pack_start($radio_no, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_use_yuv_internal_yes} = $radio_yes;
	$self->transcode_widgets->{tc_use_yuv_internal_no}  = $radio_no;
	
	# Volume Rescale
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Volume Rescale");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_volume_rescale} = $entry;

	$label = Gtk::Label->new ("nice level");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(73,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$self->transcode_widgets->{tc_nice} = $entry;

	# frame range
	++$row;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Frame Range");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize (50,undef);
	$hbox->pack_start ($entry, 0, 1, 0);

	$self->transcode_widgets->{tc_start_frame} = $entry;

	$label = Gtk::Label->new(" - ");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize (50,undef);
	$hbox->pack_start ($entry, 0, 1, 0);

	$self->transcode_widgets->{tc_end_frame} = $entry;

	# Additional Options
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("transcode options");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(220,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_options} = $entry;

	# Suggest Bitrates
	++$row;
	$button = Gtk::Button->new_with_label ("Suggest V-Bitrate");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->suggest_bitrates } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("for");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# disc cnt popup
	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize(70,undef);

	%popup_entries = (
		1 => "one",
		2 => "two",
		3 => "three",
		4 => "four",
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				my $title =$self->selected_title;
				return 1 if not $title;
				return 1 if $self->in_transcode_init;
				$title->set_tc_disc_cnt($key);
				$title->set_tc_target_size(
					$key * $title->tc_disc_size,
				);
			}, $key
		);
	}
	$hbox->pack_start($popup, 0, 1, 0);
	$self->transcode_widgets->{tc_disc_cnt_popup} = $popup;

	# disc size popup

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize(130,undef);

	%popup_entries = (
		650 => "650 MB disc(s)",
		700 => "700 MB disc(s)",
		760 => "760 MB disc(s)",
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				my $title =$self->selected_title;
				return 1 if not $title;
				return 1 if $self->in_transcode_init;
				$title->set_tc_disc_size($key);
				$title->set_tc_target_size(
					$key * $title->tc_disc_cnt,
				);
			}, $key
		);
	}
	$hbox->pack_start($popup, 0, 1, 0);
	$self->transcode_widgets->{tc_disc_size_popup} = $popup;

	# Calculated Storage -----------------------------------------

	$storage_hbox = Gtk::HBox->new;
	$storage_hbox->show;
	$vbox->pack_start ( $storage_hbox, 0, 1, 0);
	
	# Storabe Table ----------------------------------------------

	$frame = Gtk::Frame->new ("Calculated Storage");
	$frame->show;
	$storage_hbox->pack_start ($frame, 1, 1, 0);

	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 10 );
	$table->set_col_spacings ( 10 );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Video
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Size (MB):");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_video} = $label;

	# Audio
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Audio Size (MB):");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_audio} = $label;
	# Separator
	++$row;
	$sep = Gtk::HSeparator->new;
	$sep->show;
	$table->attach_defaults ($sep, 0, 2, $row, $row+1);

	# Sum
	++$row;
	$label = Gtk::Label->new ("Total Size (MB):");
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_total} = $label;

	# Buttons ----------------------------------------------------

	$frame = Gtk::Frame->new ("Transcode");
	$frame->show;
	$storage_hbox->pack_start ($frame, 0, 1, 0);

	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 10 );
	$table->set_col_spacings ( 10 );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	$row = -1;

	# preview checkbox
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$checkbox = Gtk::CheckButton->new ("Open Preview Window");
	$checkbox->show;
	$hbox->pack_start($checkbox, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Show encoded frames in a window");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_preview_checkbox} = $checkbox;

	# Transcode and split Button
	++$row;
	$button = Gtk::Button->new_with_label (" Transcode And Split ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->transcode ( split => 1 ) } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Transcoding with splitting afterwards.");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# Transcode only Button
	++$row;
	$button = Gtk::Button->new_with_label (" Transcode Video ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->transcode } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Transcoding without splitting.");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# Split only Button
	++$row;
	$button = Gtk::Button->new_with_label (" Split AVI ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->avisplit } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Splitting of a transcoded video.");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# View AVI Button
	++$row;
	$button = Gtk::Button->new_with_label (" View AVI ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->view_avi } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Viewing of a transcoded video.");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# Add Project To Cluster Button
	++$row;
	$button = Gtk::Button->new_with_label (" Add To Cluster ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->add_to_cluster } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Delegates this project to a cluster.");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# connect changed signals
	my $widgets = $self->transcode_widgets;
	foreach my $attr (qw ( tc_video_codec tc_options tc_nice
			       tc_video_af6_codec tc_video_bitrate
			       tc_video_framerate
			       tc_audio_bitrate tc_volume_rescale
			       tc_start_frame tc_end_frame )) {
		$widgets->{$attr}->signal_connect ("changed", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->$method ( $widget->get_text );
			$self->update_storage_labels if $method =~ /bitrate/;
		}, "set_$attr");
	}
	$self->transcode_widgets->{tc_use_yuv_internal_yes}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_use_yuv_internal(1);
		}
	);
	$self->transcode_widgets->{tc_use_yuv_internal_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_use_yuv_internal(0);
		}
	);
	$self->transcode_widgets->{tc_multipass_yes}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_multipass(1);
		}
	);
	$self->transcode_widgets->{tc_multipass_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_multipass(0);
		}
	);
	$self->transcode_widgets->{tc_ac3_passthrough_yes}->signal_connect (
		"clicked", sub {
			my $title = $self->selected_title;
			return 1 if not $title;
			return 1 if $self->in_transcode_init;
			$title->set_tc_ac3_passthrough(1);
			$title->set_tc_audio_bitrate(
				$title->audio_tracks
				      ->[$title->audio_channel]
				      ->{bitrate}
			);
			$self->transcode_widgets
			     ->{tc_audio_bitrate}
			     ->set_text($title->tc_audio_bitrate);
			$self->transcode_widgets
			     ->{tc_audio_bitrate}
			     ->set_editable(0);
			$self->transcode_widgets
			     ->{tc_volume_rescale}
			     ->set_editable(0);
		}
	);
	$self->transcode_widgets->{tc_ac3_passthrough_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_ac3_passthrough(0);
			$self->transcode_widgets
			     ->{tc_audio_bitrate}
			     ->set_editable(1);
			$self->transcode_widgets
			     ->{tc_volume_rescale}
			     ->set_editable(1);
		}
	);
	$self->transcode_widgets->{tc_preview_checkbox}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_preview($_[0]->active);
		}
	);
	
	return $vbox;
}

sub init_transcode_values {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	return 1 if not defined $widgets->{tc_video_codec};

	$self->set_in_transcode_init(1);

	foreach my $attr (qw ( tc_video_codec tc_options tc_nice
			       tc_video_af6_codec tc_video_bitrate
			       tc_video_framerate
			       tc_audio_bitrate tc_volume_rescale
			       tc_start_frame tc_end_frame )) {
		$widgets->{$attr}->set_text ($self->selected_title->$attr());
	}

	my $yuv             = $title->tc_use_yuv_internal;
	my $chapter_mode    = $title->tc_use_chapter_mode;
	my $multipass       = $title->tc_multipass;
	my $ac3_passthrough = $title->tc_ac3_passthrough;
	my $deinterlace     = $title->tc_deinterlace;
	my $anti_alias      = $title->tc_anti_alias;
	my $preview	    = $title->tc_preview;

	my $disc_cnt        = $title->tc_disc_cnt;
	my $disc_size       = $title->tc_disc_size;

	$widgets->{tc_use_yuv_internal_yes}->set_active($yuv);
	$widgets->{tc_use_yuv_internal_no}->set_active(!$yuv);

	$widgets->{tc_multipass_yes}->set_active($multipass);
	$widgets->{tc_multipass_no}->set_active(!$multipass);

	$widgets->{tc_ac3_passthrough_yes}->set_active($ac3_passthrough);
	$widgets->{tc_ac3_passthrough_no}->set_active(!$ac3_passthrough);
	$widgets->{tc_audio_bitrate}->set_editable( !$ac3_passthrough);

	$widgets->{tc_deinterlace_popup}->set_history ($deinterlace);
	$widgets->{tc_anti_alias_popup}->set_history ($anti_alias);

	$widgets->{tc_disc_cnt_popup}->set_history ($disc_cnt-1);
	$widgets->{tc_disc_size_popup}->set_history (($disc_size - 600) / 100);

	$widgets->{tc_preview_checkbox}->set_active ( $preview );

	if ( $title->audio_tracks->[$title->audio_channel]->{type} eq 'ac3' ) {
		$widgets->{tc_ac3_passthrough_hbox1}->show;
		$widgets->{tc_ac3_passthrough_hbox2}->show;
	} else {
		$widgets->{tc_ac3_passthrough_hbox1}->hide;
		$widgets->{tc_ac3_passthrough_hbox2}->hide;
	}
	$self->update_storage_labels;

	$self->set_in_transcode_init(0);

	1;
}

sub update_storage_labels {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	my $video_label = $self->transcode_widgets->{label_size_video};
	my $audio_label = $self->transcode_widgets->{label_size_audio};
	my $total_label = $self->transcode_widgets->{label_size_total};

	my $frames        = $title->frames;
	my $fps           = $title->frame_rate;
	my $audio_bitrate = $title->tc_audio_bitrate;
	my $video_bitrate = $title->tc_video_bitrate;

	my $runtime = $frames/$fps;
	my $video_size = int($runtime * $video_bitrate * 1000 / 1024 / 1024 / 8);
	my $audio_size = int($runtime * $audio_bitrate / 1024 / 8);
	my $total      = $video_size + $audio_size;
	
	$video_label->set_text($video_size);
	$audio_label->set_text($audio_size);
	$total_label->set_text($total);

	1;
}

sub suggest_bitrates {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	my $target_size = $title->tc_target_size;

	if ( $title->tc_ac3_passthrough ) {
		$title->set_tc_audio_bitrate(
			$title->audio_tracks
			      ->[$title->audio_channel]
			      ->{bitrate}
		);
	}
	$title->suggest_video_bitrate;

	$self->init_transcode_values;

	$self->log (
		"Bitrates suggested for $target_size MB size title #".
		$title->nr."."
	);

	1;
}

sub transcode {
	my $self = shift;
	my %par = @_;
	my ($split) = @par{'split'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;

	return $self->transcode_chapters ( split => $split )
		if $title->tc_use_chapter_mode;

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	my $pass = 1;
	my $multipass = $title->tc_multipass;

	my $open_callback = sub {
		return $title->transcode_async_start ( pass => $pass );
	};

	my $frames = 0;
	my $sum_frames = 0;

	my $progress_callback = sub {
		my %par = @_;
		my ($buffer) = @par{'buffer'};
		$buffer =~ /\[\d{6}-(\d+)\]/;
		$frames = $1 if $1;
		return $sum_frames + $frames;
	};

	my $close_callback = sub {
		my %par = @_;
		my ($output, $progress) = @par{'output','progress'};

		$title->transcode_async_stop (
			fh     => $progress->fh,
			output => $output,
		);

		if ( $multipass and $pass == 1 ) {
			++$pass;
			$progress->set_label (
				"Transcoding title #".$title->nr." (Pass 2/2)"
			);
			$progress->init_pipe (
				fh => $title->transcode_async_start ( pass => 2 )
			);
			$sum_frames += $frames;
			$frames = 0;
			return 'continue';

		} else {
			return $split ? sub {
				$self->avisplit ( title => $title )
			} : 'finished';
		}
	};

	my $cancel_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};

		system ("killall -2 transcode");
		sleep 2;
		close ($progress->fh);
	};

	my $max_value;
	if ( $title->tc_start_frame ne '' or
	     $title->tc_end_frame ne '' ) {
	     	$max_value = $title->tc_end_frame;
		$max_value ||= $title->frames;
	} else {
		$max_value = $title->frames;
	}

	$max_value *= 2 if $multipass;

	my $label;
	if ( $multipass ) {
		$label = "Analyzing title #".$title->nr." (Pass 1/2)";
	} else {
		$label = "Transcoding title #".$title->nr;
	}

	$self->comp('progress')->open (
		label             => $label,
		need_output       => 0,
		show_fps	  => 1,
		show_percent      => 1,
		show_eta          => 1,
		max_value         => $max_value,
		open_callback     => $open_callback,
		progress_callback => $progress_callback,
		cancel_callback   => $cancel_callback,
		close_callback    => $close_callback,
	);

	1;
}

sub transcode_chapters {
	my $self = shift;
	my %par = @_;
	my ($split) = @par{'split'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;

	my $chapter_mode = $title->tc_use_chapter_mode;
	croak "Title is not in chapter mode" if not $chapter_mode;

	if ( $title->tc_use_chapter_mode and $split ) {
		$self->message_window (
			message => "Splitting an AVI file in\n".
				   "Chapter Mode makes no sense."
		);
		return 1;
	}

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	my @chapters = @{$title->get_chapters};

	if ( not @chapters ) {
		$self->message_window (
			message => "No chapters selected."
		);
		return;
	}

	my $cnt = 1;

	my $pass = 1;
	my $multipass = $title->tc_multipass;
	
	my $frames = 0;
	my $sum_frames = 0;

	my $chapter = shift @chapters;

	$title->set_actual_chapter($chapter);

	my $open_callback = sub {
		return $title->transcode_async_start ( pass => $pass );
	};

	my $progress_callback = sub {
		return $cnt if $chapter_mode eq 'select';
		my %par = @_;
		my ($buffer) = @par{'buffer'};
		$buffer =~ /\[\d{6}-(\d+)\]/;
		$frames = $1 if $1;
		return $sum_frames+$frames;
	};

	my $close_callback = sub {
		my %par = @_;
		my ($output, $progress) = @par{'output','progress'};

		$title->transcode_async_stop (
			fh     => $progress->fh,
			output => $output,
		);

		$sum_frames += $frames;
		$frames = 0;
	
		if ( $multipass and $pass == 1 ) {
			++$pass;
			$progress->set_label (
				"Transcoding chapter $chapter of title #".
				$title->nr." (Pass 2/2)"
			);
			$progress->init_pipe (
				fh => $title->transcode_async_start ( pass => 2 )
			);
			return 'continue';

		} else {
			$chapter = shift @chapters;
			return 'finished' if not defined $chapter;

			$pass = 1;
			$title->set_actual_chapter($chapter);

			if ( $multipass ) {
				$progress->set_label (
					"Analyzing chapter $chapter of title #".
					$title->nr." (Pass 1/2)"
				);
			} else {
				$progress->set_label (
					"Transcoding chapter $chapter of title #".
					$title->nr
				);
			}

			$progress->init_pipe (
				fh => $title->transcode_async_start ( pass => 2 )
			);

			return 'continue';
		}
	};

	my $cancel_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};

		system ("killall -2 transcode");
		sleep 2;
		close ($progress->fh);
		$title->set_actual_chapter(undef);
	};

	my $max_value;
	if ( $title->tc_start_frame ne '' and
	     $title->tc_end_frame ne '' ) {
		$max_value = $title->tc_end_frame;
		$self->log (
			"Frame selection detected: only the first ".
			"chapter will be processed"
		);
		@chapters = ();

	} elsif ( $chapter_mode eq 'select' ) {
		$max_value = @chapters + 1;

	} else {
		$max_value = $title->frames;
	}

	$max_value *= 2 if $multipass;

	my $label;
	if ( $multipass ) {
		$label = "Analyzing chapter $chapter of title #".
			 $title->nr." (Pass 1/2)";
	} else {
		$label = "Transcoding chapter $chapter of title #".
			 $title->nr;
	}

	$self->comp('progress')->open (
		label             => $label,
		need_output       => 0,
		show_percent      => ($chapter_mode ne 'select'),
		show_fps	  => ($chapter_mode ne 'select'),
		show_eta	  => ($chapter_mode ne 'select'),
		max_value         => $max_value,
		open_callback     => $open_callback,
		progress_callback => $progress_callback,
		cancel_callback   => $cancel_callback,
		close_callback    => $close_callback,
	);

	1;
}

sub avisplit {
	my $self = shift;
	my %par = @_;
	my ($title) = @par{'title'};

	$title ||= $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;
	
	my $filename = $title->avi_file;

	if ( $title->tc_use_chapter_mode ) {
		$self->message_window (
			message => "Splitting an AVI file in\n".
				   "chapter mode is currently not supported."
		);
		return 1;
	}

	if ( not -f $filename ) {
		$self->message_window (
			message => "You first have to transcode this title."
		);
		return 1;
	}

	my $open_callback = sub {
		return $title->split_async_start;
	};

	my $progress_callback = sub {
		my %par = @_;
		my ($buffer) = @par{'buffer'};
		$buffer =~ /\(\d{6}-(\d+)\),\s+(.*?)\[.*?$/;
		return $1;
	};

	my $close_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};
		$title->split_async_stop ( fh => $progress->fh );
		return 'finished';
	};

	my $cancel_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};
		close ($progress->fh );
		return 1;
	};

	$self->comp('progress')->open (
		label             => "Splitting AVI of title #".$title->nr,
		need_output       => 0,
		show_fps	  => 1,
		show_percent      => 1,
		show_eta          => 1,
		max_value         => $title->frames,
		open_callback     => $open_callback,
		progress_callback => $progress_callback,
		cancel_callback   => $cancel_callback,
		close_callback    => $close_callback,
	);

	1;
}

sub view_avi {
	my $self = shift;
	my %par = @_;
	my ($title) = @par{'title'};

	$title ||= $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;

	if ( $title->tc_use_chapter_mode ) {
		my $chapters = $title->get_chapters;
		my (@filenames, $filename);
		foreach my $chapter ( @{$chapters} ) {
			$title->set_actual_chapter ($chapter);
			$filename = $title->avi_file;
			push @filenames, $filename if -f $filename;
		}
		$title->set_actual_chapter(undef);
		
		if ( not @filenames ) {
			$self->message_window (
				message => "You first have to transcode this title."
			);
			return 1;
		}

		system ("xine ".join(" ", @filenames)." -p &");

	} else {
		my $filename = $title->avi_file;
		$filename =~ s/\.avi$//;
		system ("xine ${filename}* -p &");

	}
	
	1;
}

sub add_to_cluster {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	if ( $title->tc_use_chapter_mode ) {
		$self->message_window (
			message => "Titles in chapter mode are not supported"
		);
		return 1;
	}

	if ( $title->tc_ac3_passthrough ) {
		$self->message_window (
			message => "Titles with AC3 passthrough mode are currently not supported"
		);
		return 1;
	}

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	# calculate program stream units, if not already done
	$title->calc_program_stream_units
		if not $title->program_stream_units or
		   not @{$title->program_stream_units};

	$self->comp('main')->cluster_control;
	
	my $cluster = eval { $self->comp('cluster') };
	return if not $cluster;

	$cluster->add_project (
		project  => $self->project,
		title_nr => $title->nr,
	);
	
	1;
}

1;
