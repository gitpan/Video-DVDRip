# $Id: TranscodeTab.pm,v 1.15 2001/12/10 20:43:26 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

sub transcode_widgets		{ shift->{transcode_widgets}		}	# href
sub set_transcode_widgets	{ shift->{transcode_widgets}	= $_[1] }


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
	    $storage_hbox);

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

	# Viewing Angle
	my $row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Viewing Angle");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(40,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_viewing_angle} = $entry;

	# Video Codec
	++$row;
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

	# Suggest Bitrates
	++$row;
	$button = Gtk::Button->new_with_label ("Suggest Bitrates");
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
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				my $title =$self->selected_title;
				return 1 if not $title;
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
		600 => "600 MB disc(s)",
		700 => "700 MB disc(s)",
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				my $title =$self->selected_title;
				return 1 if not $title;
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

	# frame range
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

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

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Specify frame range for test transcoding. Leave ".
				  "both fields empty for full processing.");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# Transcode and split Button
	++$row;
	$button = Gtk::Button->new_with_label (" Transcode And Split ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->transcode ( split => 1 ) } );
	$table->attach_defaults ($button, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("This transcodes and splits the resulting ".
				  "AVI file into chunks of the selected size.");
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
	$label = Gtk::Label->new ("This transcodes the video  ".
				  "without splitting the AVI file.");
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
	$label = Gtk::Label->new ("This splits an already transcoded AVI file.".
				  "                 ");
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
	$label = Gtk::Label->new ("View transcoded AVI file of this title.".
				  "                               ");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	# connect changed signals
	my $widgets = $self->transcode_widgets;
	foreach my $attr (qw ( tc_viewing_angle tc_video_codec
			       tc_video_af6_codec tc_video_bitrate
			       tc_audio_bitrate tc_volume_rescale
			       tc_start_frame tc_end_frame )) {
		$widgets->{$attr}->signal_connect ("changed", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			$self->selected_title->$method ( $widget->get_text );
			$self->update_storage_labels if $method =~ /bitrate/;
		}, "set_$attr");
	}
	$self->transcode_widgets->{tc_use_yuv_internal_yes}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_yuv_internal(1);
		}
	);
	$self->transcode_widgets->{tc_use_yuv_internal_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_yuv_internal(0);
		}
	);
	$self->transcode_widgets->{tc_multipass_yes}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_multipass(1);
		}
	);
	$self->transcode_widgets->{tc_multipass_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_multipass(0);
		}
	);
	
	return $vbox;
}

sub init_transcode_values {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	return 1 if not defined $widgets->{tc_viewing_angle};

	foreach my $attr (qw ( tc_viewing_angle tc_video_codec
			       tc_video_af6_codec tc_video_bitrate
			       tc_audio_bitrate tc_volume_rescale
			       tc_start_frame tc_end_frame )) {
		$widgets->{$attr}->set_text ($self->selected_title->$attr());
	}

	my $yuv         = $title->tc_use_yuv_internal;
	my $multipass   = $title->tc_multipass;
	my $deinterlace = $title->tc_deinterlace;
	my $anti_alias  = $title->tc_anti_alias;

	my $disc_cnt    = $title->tc_disc_cnt;
	my $disc_size   = $title->tc_disc_size;

	$widgets->{tc_use_yuv_internal_yes}->set_active($yuv);
	$widgets->{tc_use_yuv_internal_no}->set_active(!$yuv);

	$widgets->{tc_multipass_yes}->set_active($multipass);
	$widgets->{tc_multipass_no}->set_active(!$multipass);

	$widgets->{tc_deinterlace_popup}->set_history ($deinterlace);
	$widgets->{tc_anti_alias_popup}->set_history ($anti_alias);

	$widgets->{tc_disc_cnt_popup}->set_history ($disc_cnt-1);
	$widgets->{tc_disc_size_popup}->set_history ($disc_size==600 ? 0 : 1);

	$self->update_storage_labels;

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

	$title->set_tc_audio_bitrate(128);
	$title->suggest_video_bitrate;

	$self->init_transcode_values;

	1;
}

sub transcode {
	my $self = shift;
	my %par = @_;
	my ($split) = @par{'split'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	my $max_value;
	if ( $title->tc_start_frame ne '' and
	     $title->tc_end_frame ne '' ) {
		$max_value = $title->tc_end_frame;
	} else {
		$max_value = $title->frames;
	}

	my $fh = $title->transcode_async_start ( pass => 1 );

	use FileHandle;
	my $DEBUG = FileHandle->new;
	open ($DEBUG, "> transcode.".$title->project->name.".".$title->nr.".log");

	my $multipass = $title->tc_multipass;
	my $pass = 1;

	my $label_prefix;
	if ( $multipass ) {
		$label_prefix = "Analyzing Video (Pass 1/2):";

	} else {
		$label_prefix = "Transcoding Video:";
	}

	$label_prefix =~ s/:$/ (split afterwards):/ if $split;

	$self->comp('progress')->open_continious_progress (
		max_value => $max_value,
		label     => "Transcoding Video",
		fh        => $fh,
		get_progress_callback => sub {
			my %par = @_;
			my ($buffer) = @par{'buffer'};
			print $DEBUG $buffer;
			$buffer =~ /\[\d{6}-(\d+)\],\s+(.*?)\[.*?$/;
			my $value = $1;
			my $label = "$label_prefix $2";
			$label =~ s/ +/ /g;
			$label =~ s/,\s*$//;
			$label =~ s/\%/%%/g;
			return ($value, $label);
		},
		finished_callback => sub {
			my %par = @_;
			my ($output) = @par{'output'};
			
			$title->transcode_async_stop (
				fh     => $fh,
				output => $output,
			);
			
			if ( $multipass and $pass == 1 ) {
				++$pass;
				$fh = $title->transcode_async_start ( pass => 2 );
				$self->comp('progress')->set_fh ($fh);
				$label_prefix = "Transcoding Video (Pass 2/2):";
				return 1;

			} else {
				$self->avisplit ( title => $title ) if $split;
				close $DEBUG;
				return;
			}
		},
		cancel_callback => sub {
			system ("killall -2 transcode");
			sleep 2;
			close $fh;
			close $DEBUG;
		},
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

	if ( not -f $filename ) {
		$self->message_window (
			message => "You first have to transcode this title."
		);
		return 1;
	}

	my $fh = $title->split_async_start;

	$self->comp('progress')->open_continious_progress (
		max_value => $title->frames,
		label     => "Splitting AVI",
		fh        => $fh,
		get_progress_callback => sub {
			my %par = @_;
			my ($buffer) = @par{'buffer'};
			$buffer =~ /\(\d{6}-(\d+)\),\s+(.*?)\[.*?$/;
			return $1;
		},
		finished_callback => sub {
			$title->split_async_stop ( fh => $fh );
			return;
		},
		cancel_callback => sub {
			close $fh;
		},
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
	
	my $filename = $title->avi_file;

	if ( not -f $filename ) {
		$self->message_window (
			message => "You first have to transcode this title."
		);
		return 1;
	}

	system ("xine $filename -p &");
	
	1;
}

1;
