# $Id: TranscodeTab.pm,v 1.48 2002/07/15 07:29:23 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Video::DVDRip::GUI::MinSizeGroup;

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

	# VBox
	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	# Frame with Selected Title
	my $selected_title = $self->create_selected_title;
	$vbox->pack_start ( $selected_title, 0, 1, 0);

	# Left HSize Group
	my $left_hsize_group = Video::DVDRip::GUI::MinSizeGroup->new (
		type => 'h',
	);

	# Right HSize Group
	my $right_hsize_group = Video::DVDRip::GUI::MinSizeGroup->new (
		type => 'h',
	);
	
	# Build Frames
	my $video_options = $self->create_video_options (
		hsize_group => $left_hsize_group
	);
	my $audio_options = $self->create_audio_options (
		hsize_group => $left_hsize_group
	);
	my $video_bitrate_calc = $self->create_video_bitrate_calc (
		hsize_group => $right_hsize_group
	);
	my $operate = $self->create_operate (
		hsize_group => $right_hsize_group
	);
	my $general_options = $self->create_general_options (
		hsize_group => $right_hsize_group
	);
	my $calculated_storage = $self->create_calculated_storage (
		hsize_group => $right_hsize_group
	);
	
	# Put frames into table
	my $table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 7 );
	$table->set_col_spacings ( 7 );
	$vbox->pack_start ($table, 0, 1, 0);

	$table->attach_defaults ($video_options, 	0, 1, 0, 2);

	$table->attach_defaults ($video_bitrate_calc, 	1, 2, 0, 1);
	$table->attach_defaults ($calculated_storage, 	1, 2, 1, 2);


	$table->attach_defaults ($audio_options, 	0, 1, 2, 3);
	$table->attach_defaults ($general_options, 	1, 2, 2, 3);

	$table->attach_defaults ($operate, 		0, 2, 3, 4);

	# connect changed signals
	my $widgets = $self->transcode_widgets;
	
	# text entry signals
	foreach my $attr (qw ( tc_video_codec tc_options tc_nice
			       tc_video_af6_codec tc_video_bitrate
			       tc_video_framerate
			       tc_audio_bitrate tc_volume_rescale
			       tc_start_frame tc_end_frame
			       tc_target_size )) {
		$widgets->{$attr}->signal_connect ("changed", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			my $title = $self->selected_title;
			$title->$method ( $widget->get_text );
			if ( $method =~ /audio|target/ ) {
				$title->calc_video_bitrate;
				$widgets->{tc_video_bitrate}
					->set_text ( $title->tc_video_bitrate );
			}
			$self->update_storage_labels
				if $method eq 'set_tc_video_bitrate';
		}, "set_$attr");
	}

	$widgets->{tc_video_codec}->signal_connect ("changed", sub {
		my ($widget) = @_;
		return 1 if not $self->selected_title;
		return 1 if $self->in_transcode_init;
		$self->selected_title->calc_video_bitrate;
		$self->init_transcode_values;
	});
	
	# radio button signals
	
	foreach my $attr (qw ( tc_use_yuv_internal tc_multipass
			       tc_preview tc_audio_drc tc_psu_core )) {
		$widgets->{$attr."_yes"}->signal_connect ( "clicked", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->$method(1);
		}, "set_$attr");
		$widgets->{$attr."_no"}->signal_connect ( "clicked", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->$method(0);
		}, "set_$attr");
	}

	# Audio Codec Signals

	$self->transcode_widgets->{tc_ac3_passthrough_yes}->signal_connect (
		"clicked", sub {
			my $title = $self->selected_title;
			return 1 if not $title;
			return 1 if $self->in_transcode_init;
			$title->set_tc_ac3_passthrough(1);
			$title->calc_video_bitrate;
			$self->init_transcode_values;
		}
	);

	$self->transcode_widgets->{tc_ac3_passthrough_no}->signal_connect (
		"clicked", sub {
			my $title = $self->selected_title;
			return 1 if not $title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->set_tc_ac3_passthrough(0);
			$title->calc_video_bitrate;
			$self->init_transcode_values;
		}
	);

	return $vbox;
}

sub create_video_options {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("Video Options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 7, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 7 );
	$table->set_col_spacings ( 7 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Deinterlace
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Deinterlace Mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		0        => "No Deinterlacing",
		1        => "Interpolate Scanlines (fast)",
		2        => "Handled By Encoder (may segfault)",
		3        => "Zoom To Full Frame (slow)",
		'32detect' => "Automatic deinterlacing of single frames",
	);
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if not $self->selected_title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_deinterlace($key)
			}, $key
		);
	}
	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->transcode_widgets->{tc_deinterlace_popup} = $popup;

	# Antialias
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Antialias Mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		0 => "No Antialiasing",
		1 => "Process De-Interlace Effects",
		2 => "Process Resize Effects",
		3 => "Process Full Frame (slow)",
	);
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if not $self->selected_title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_anti_alias($key)
			}, $key
		);
	}
	$table->attach_defaults ($popup, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_anti_alias_popup} = $popup;

	# Video Codec
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Codec");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;

	$entry = Gtk::Combo->new;
	$entry->show;
	$entry->set_popdown_strings ("SVCD","VCD","divx4","divx5","xvid","xvidcvs","fame","af6","opendivx");
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_codec} = $entry->entry;

	# AF6 Codec
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("af6 Video Codec");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_af6_codec} = $entry;

	# Video Framerate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Framerate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Combo->new;
	$entry->show;
	$entry->set_popdown_strings ("25", "23.976", "29.97");
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	
	$label = Gtk::Label->new("fps");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_framerate} = $entry->entry;

	# Use YUV Internal
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Use YUV Internal");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

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
	
	# Enable DivX Multipass Encoding
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("DivX Multipass");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

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

	return $frame;
}

sub create_audio_options {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no);

	my (@ac3_hide, @ac3_keep, @mpeg_hide);
	my $ac3_vsize_group = Video::DVDRip::GUI::MinSizeGroup->new (
		type => 'v',
	);

	# Frame
	$frame = Gtk::Frame->new ("Audio Options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 7 );
	$table->set_col_spacings ( 7 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# MP3 or AC3 Audio Passthrough?
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Audio Codec");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $radio_mp3 = Gtk::RadioButton->new ("MP3");
	$radio_mp3->show;
	$hbox->pack_start($radio_mp3, 0, 1, 0);
	my $radio_ac3 = Gtk::RadioButton->new ("AC3 Passthrough", $radio_mp3);
	$radio_ac3->show;
	$hbox->pack_start($radio_ac3, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_ac3_passthrough_no}  = $radio_mp3;
	$self->transcode_widgets->{tc_ac3_passthrough_yes} = $radio_ac3;
	$self->transcode_widgets->{tc_ac3_passthrough_radio} = $radio_ac3;
	
	# Audio Bitrate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Audio Bitrate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Combo->new;
	$entry->show;
	$entry->set_popdown_strings (96, 128, 160, 192, 256, 320, 384);
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("kbit/s");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_audio_bitrate} = $entry->entry;
	$self->transcode_widgets->{tc_audio_bitrate_combo} = $entry;

	# a52_drc_off
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Range Compression");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	push @ac3_keep, $hbox;
	push @ac3_hide, $label;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $radio_yes = Gtk::RadioButton->new ("Yes");
	$radio_yes->show;
	$hbox->pack_start($radio_yes, 0, 1, 0);
	my $radio_no = Gtk::RadioButton->new ("No", $radio_yes);
	$radio_no->show;
	$hbox->pack_start($radio_no, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_audio_drc_yes} = $radio_yes;
	$self->transcode_widgets->{tc_audio_drc_no}  = $radio_no;

	push @ac3_keep, $hbox;
	push @ac3_hide, ($radio_yes, $radio_no);

	# Volume Rescale
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Volume Rescale");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	push @ac3_keep, $hbox;
	push @ac3_hide, $label;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	push @ac3_keep, $hbox;
	push @ac3_hide, $entry;

	$self->transcode_widgets->{tc_volume_rescale} = $entry;

	# MP3 Encoder Quality
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("MP3 Quality");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	push @ac3_keep, $hbox;
	push @ac3_hide, ($label, $popup);
	push @mpeg_hide, ($label, $popup);

	%popup_entries = (
		0 => "0 - best but slower",
		1 => "1",
		2 => "2",
		3 => "3",
		4 => "4",
		5 => "5 - medium",
		6 => "6",
		7 => "7",
		8 => "8",
		9 => "9 - low but faster",
	);
	
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if not $self->selected_title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_mp3_quality($key)
			}, $key
		);
	}

	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->transcode_widgets->{tc_mp3_quality_popup} = $popup;

	# build vsize group of @ac3_keep widgets
	$ac3_vsize_group->add ($_) foreach @ac3_keep;
	$self->transcode_widgets->{tc_ac3_hide}  = \@ac3_hide;
	$self->transcode_widgets->{tc_mpeg_hide} = \@mpeg_hide;

	return $frame;
}

sub create_video_bitrate_calc {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("Video Bitrate Calculation");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 3, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 7 );
	$table->set_col_spacings ( 7 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Target Media
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target Media");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

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
				if ( $title->tc_video_codec ne 'VCD' ) {
					$title->set_tc_target_size(
						$key * $title->tc_disc_size,
					);
					$self->transcode_widgets
					     ->{tc_target_size}
					     ->set_text ($title->tc_target_size);
				}
			}, $key
		);
	}
	$hbox->pack_start($popup, 1, 1, 0);
	
	$self->transcode_widgets->{tc_disc_cnt_popup} = $popup;

	$label = Gtk::Label->new ("x");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		650 => "650",
		700 => "700",
		760 => "760",
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				my $title = $self->selected_title;
				return 1 if not $title;
				return 1 if $self->in_transcode_init;
				$title->set_tc_disc_size($key);
				if ( $title->tc_video_codec ne 'VCD' ) {
					$title->set_tc_target_size(
						$key * $title->tc_disc_cnt,
					);
					$self->transcode_widgets
					     ->{tc_target_size}
					     ->set_text ($title->tc_target_size);
				}
			}, $key
		);
	}

	$self->transcode_widgets->{tc_disc_size_popup} = $popup;

	$hbox->pack_start($popup, 1, 1, 0);

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	# Target Size
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target Size");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_target_size} = $entry;

	# Video Bitrate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Bitrate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("kbit/s");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_bitrate} = $entry;

	return $frame;
}

sub create_operate {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($button, $button_box);

	# Frame
	$frame = Gtk::Frame->new ("Operate");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# ButtonBox
	$button_box = new Gtk::HButtonBox();
	$button_box->show;
	$button_box->set_spacing_default(2);
	$frame_hbox->pack_start ($button_box, 1, 0, 1);

	# Transcode and split Button
	$button = Gtk::Button->new_with_label ("Transcode + Split");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->transcode ( split => 1 ) } );
	$button_box->add ($button);

	# Transcode only Button
	$button = Gtk::Button->new_with_label ("Transcode");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->transcode } );
	$button_box->add ($button);

	# Split only Button
	$button = Gtk::Button->new_with_label ("Split AVI");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->avisplit } );
	$button_box->add ($button);

	$self->transcode_widgets->{avisplit_button} = $button;

	# View AVI Button
	$button = Gtk::Button->new_with_label ("View AVI");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->view_avi } );
	$button_box->add ($button);

	$self->transcode_widgets->{view_avi_button} = $button;

	# Add Project To Cluster Button
	$button = Gtk::Button->new_with_label ("Add To Cluster");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->add_to_cluster } );
	$button_box->add ($button);

	$self->transcode_widgets->{cluster_button} = $button;

	return $frame;
}

sub create_general_options {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("General Options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 7 );
	$table->set_col_spacings ( 7 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# frame range
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Frame Range");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

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
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$hbox->pack_start($entry, 1, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->transcode_widgets->{tc_options} = $entry;

	# nice level
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Process nice level");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Combo->new;
	$entry->show;
	$entry->set_popdown_strings (undef,5,10,15,19);
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_nice} = $entry->entry;

	# Open Preview Window
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Preview Window");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $radio_yes = Gtk::RadioButton->new ("Yes");
	$radio_yes->show;
	$hbox->pack_start($radio_yes, 0, 1, 0);
	my $radio_no = Gtk::RadioButton->new ("No", $radio_yes);
	$radio_no->show;
	$hbox->pack_start($radio_no, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_preview_yes} = $radio_yes;
	$self->transcode_widgets->{tc_preview_no}  = $radio_no;
	
	# Use new PSU core
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Use PSU core");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$radio_yes = Gtk::RadioButton->new ("Yes");
	$radio_yes->show;
	$hbox->pack_start($radio_yes, 0, 1, 0);
	$radio_no = Gtk::RadioButton->new ("No", $radio_yes);
	$radio_no->show;
	$hbox->pack_start($radio_no, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_psu_core_yes} = $radio_yes;
	$self->transcode_widgets->{tc_psu_core_no}  = $radio_no;
	
	return $frame;
}

sub create_calculated_storage {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("Calculated Storage");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( 7 );
	$table->set_col_spacings ( 7 );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Video
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video Size (MB):");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);
	$hsize_group->add ($hbox);

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
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_audio} = $label;

	# Separator
	++$row;
	my $sep = Gtk::HSeparator->new;
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
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_total} = $label;

	return $frame;
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
			       tc_video_framerate tc_target_size
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
	my $mp3_quality	    = $title->tc_mp3_quality;
	my $video_codec     = $title->tc_video_codec;
	my $audio_drc       = $title->tc_audio_drc;
	my $psu_core        = $title->tc_psu_core;

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
	$widgets->{tc_mp3_quality_popup}->set_history ($mp3_quality);

	my %disc_size_history = (
		650 => 0,
		700 => 1,
		760 => 2,
	);

	$widgets->{tc_disc_cnt_popup}->set_history ($disc_cnt-1);
#	$widgets->{tc_disc_size_popup}->set_history (($disc_size - 600) / 100);
	$widgets->{tc_disc_size_popup}->set_history ($disc_size_history{$disc_size});

	$widgets->{tc_preview_yes}->set_active($preview);
	$widgets->{tc_preview_no}->set_active(!$preview);

	$widgets->{tc_audio_drc_yes}->set_active($audio_drc);
	$widgets->{tc_audio_drc_no}->set_active(!$audio_drc);

	$widgets->{tc_psu_core_yes}->set_active($psu_core);
	$widgets->{tc_psu_core_no}->set_active(!$psu_core);

	if ( $title->audio_tracks->[$title->audio_channel]->{type} eq 'ac3' ) {
		$widgets->{tc_ac3_passthrough_radio}->show;
	} else {
		$widgets->{tc_ac3_passthrough_radio}->hide;
	}
	$self->update_storage_labels;

	if ( $video_codec eq 'SVCD' or $video_codec eq 'VCD' ) {
		$self->switch_to_mpeg_encoding;
	} else {
		$self->switch_to_divx_encoding;
	}

	$self->set_in_transcode_init(0);

	1;
}

sub switch_to_mpeg_encoding {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	foreach my $attr ( qw ( tc_video_af6_codec tc_multipass_yes
				tc_multipass_no) ) {
		$widgets->{$attr}->set_sensitive(0);
	}

	my $video_codec = $title->tc_video_codec;

	$widgets->{tc_ac3_passthrough_no}->child->set("MP2");
	$widgets->{tc_ac3_passthrough_yes}->hide;
	$widgets->{tc_audio_bitrate_combo}->set_sensitive ( $video_codec eq 'SVCD' );

	$widgets->{avisplit_button}->set_sensitive(0);
	$widgets->{cluster_button}->set_sensitive(0);
	$widgets->{view_avi_button}->child->set("View MPEG");

	if ( $video_codec eq 'VCD' ) {
		$widgets->{tc_video_bitrate}->set_sensitive(0);
		$widgets->{tc_disc_cnt_popup}->set_sensitive(0);
		$widgets->{tc_target_size}->set_text("");
		$widgets->{tc_target_size}->set_sensitive(0);
	} else {
		$widgets->{tc_video_bitrate}->set_sensitive(1);
		$widgets->{tc_disc_cnt_popup}->set_sensitive(1);
		$widgets->{tc_disc_size_popup}->set_sensitive(1);
		$widgets->{tc_target_size}->set_sensitive(1);
	}

	$_->hide foreach @{$widgets->{tc_mpeg_hide}};
	
	1;
}

sub switch_to_divx_encoding {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	foreach my $attr ( qw ( tc_video_af6_codec tc_multipass_yes
				tc_multipass_no) ) {
		$widgets->{$attr}->set_sensitive(1);
	}

	$widgets->{tc_ac3_passthrough_no}->child->set("MP3");
	$widgets->{tc_ac3_passthrough_yes}->show;

	$widgets->{avisplit_button}->set_sensitive(1);
	$widgets->{cluster_button}->set_sensitive(1);
	$widgets->{view_avi_button}->child->set("View AVI");

	if ( $title->tc_ac3_passthrough ) {
		$_->hide foreach @{$widgets->{tc_ac3_hide}};
		$widgets->{tc_audio_bitrate_combo}->set_sensitive (0);
	} else {
		$_->show foreach @{$widgets->{tc_ac3_hide}};
		$widgets->{tc_audio_bitrate_combo}->set_sensitive (1);
	}

	$widgets->{tc_video_bitrate}->set_sensitive(1);
	$widgets->{tc_disc_cnt_popup}->set_sensitive(1);
	$widgets->{tc_disc_size_popup}->set_sensitive(1);
	$widgets->{tc_target_size}->set_sensitive(1);
	
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
	if ( $title->tc_psu_core and
	    ($title->tc_start_frame or $title->tc_end_frame) ) {
		$self->message_window (
			message => "You can't select a frame range with psu core."
		);
		return 1;
	}


	my $pass = 1;
	my $multipass = $title->tc_multipass;
	my $mpeg      = $title->tc_video_codec =~ /^S?VCD$/;

	my $open_callback = sub {
		return $title->transcode_async_start (
			pass => $pass, split => $split
		)
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
			pass   => $pass,
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
			if ( $mpeg ) {
				return sub {
					$self->mplex (
						title => $title,
						split => $split,
					);
				};
			}
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
		close ($progress->fh) if $progress->fh;
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

	my $mpeg     = $title->tc_video_codec =~ /^S?VCD$/;
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
		my %par = @_;
		my ($buffer) = @par{'buffer'};
		$buffer =~ /\[\d{6}-(\d+)\]/;
		$frames = $1 if $1;
		return $sum_frames+$frames;
	};

	my $multiplexed = 0;
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

		}

		if ( $mpeg and not $multiplexed ) {
			$progress->set_label (
				"Multiplexing MPEG Video and Audio of chapter $chapter"
			);
			$progress->init_pipe (
				fh => $title->mplex_async_start ( split => $split )
			);
			$multiplexed = 1;
			return "continue";
		
		} else {
			$chapter = shift @chapters;
			return 'finished' if not defined $chapter;

			$pass = 1;
			$multiplexed = 0;
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
			"Frame selection in chapter mode: only the first ".
			"chapter will be processed"
		);
		@chapters = ();

	} else {
		$max_value += $title->chapter_frames->{$_}
			for ( $chapter, @chapters );
	}

	$max_value ||= $title->frames;	# fallback, if no chapter frame cnt avail.
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
		show_percent      => 1,
		show_fps	  => 1,
		show_eta	  => 1,
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
		my ($progress, $output) = @par{'progress','output'};
		$title->split_async_stop (#
			fh     => $progress->fh,
			output => $output
		);
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

sub mplex {
	my $self = shift;
	my %par = @_;
	my ($title, $split) = @par{'title','split'};

	$title ||= $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;
	
	my $filename = $title->avi_file;

	if ( not -f "$filename.mpa" ) {
		$self->message_window (
			message => "You first have to transcode this title."
		);
		return 1;
	}

	my $open_callback = sub {
		return $title->mplex_async_start ( split => $split );
	};

	my $progress_callback = sub { return 0 };

	my $close_callback = sub {
		my %par = @_;
		my ($progress, $output) = @par{'progress','output'};
		$title->mplex_async_stop (
			fh => $progress->fh,
			output => $output,
			split => $split,
		);
		return 'finished';
	};

	my $cancel_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};
		close ($progress->fh );
		return 1;
	};

	$self->comp('progress')->open (
		label             => "Multiplexing MPEG of title #".$title->nr,
		need_output       => 0,
		show_fps	  => 0,
		show_percent      => 0,
		show_eta          => 0,
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

	my $command = $title->get_view_avi_command (
		command_tmpl => $self->config('play_file_command'),
	);

	system ($command." &");
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

	if ( $title->tc_psu_core ) {
		$self->message_window (
			message => "PSU core mode currently not supported"
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
