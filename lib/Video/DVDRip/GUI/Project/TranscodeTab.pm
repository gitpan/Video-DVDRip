# $Id: TranscodeTab.pm,v 1.83 2003/02/08 11:29:21 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Video::DVDRip::GUI::MinSizeGroup;
use Video::DVDRip::GUI::Project::TranscodeTabAudio;

use Carp;
use strict;

my $TABLE_SPACING = 5;

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
		hsize_group => $right_hsize_group
	);
	my $video_bitrate_calc = $self->create_video_bitrate_calc (
		hsize_group => $left_hsize_group
	);
	my $operate = $self->create_transcode_operate (
		hsize_group => $right_hsize_group
	);
	my $general_options = $self->create_general_options (
		hsize_group => $right_hsize_group
	);
	my $calculated_storage = $self->create_calculated_storage (
		hsize_group => $left_hsize_group
	);
	my $container_options = $self->create_container_options (
		hsize_group => $left_hsize_group
	);
	
	# Put frames into table
	my $table = Gtk::Table->new ( 5, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$vbox->pack_start ($table, 0, 1, 0);

	$table->attach_defaults ($container_options, 	0, 1, 0, 1);
	$table->attach_defaults ($video_options, 	0, 1, 1, 2);

	$table->attach_defaults ($audio_options, 	1, 2, 0, 2);

	$table->attach_defaults ($video_bitrate_calc, 	0, 1, 2, 3);
	$table->attach_defaults ($calculated_storage, 	0, 1, 3, 4);

	$table->attach_defaults ($general_options, 	1, 2, 2, 4);

	$table->attach_defaults ($operate, 		0, 2, 4, 5);

	# connect changed signals
	my $widgets = $self->transcode_widgets;
	
	# text entry signals
	foreach my $attr (qw ( tc_video_codec tc_options tc_nice
			       tc_video_af6_codec tc_video_bitrate
			       tc_video_framerate tc_execute_afterwards
			       tc_start_frame tc_end_frame
			       tc_target_size )) {
		$widgets->{$attr}->signal_connect ("changed", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			my $title = $self->selected_title;

			$title->$method ( $widget->get_text );
			if ( $method eq "set_tc_target_size" ) {
				$self->calc_video_bitrate;
			}
			$self->update_storage_labels
				if $method eq 'set_tc_video_bitrate';
			if ( $attr eq 'tc_video_codec' ) {
				if ( $widget->get_text eq 'VCD' ) {
					$self->burn_widgets
					     ->{burn_cd_type_vcd}->set_active(1);
				} elsif ( $widget->get_text eq 'SVCD' ) {
					$self->burn_widgets
					     ->{burn_cd_type_svcd}->set_active(1);
				} else {
					$self->burn_widgets
					     ->{burn_cd_type_iso}->set_active(1);
				}
				$self->selected_title->calc_video_bitrate;
				$self->init_transcode_values ( no_codec_combo => 1 );
			}
			if ( $attr eq 'tc_start_frame' or $attr eq 'tc_end_frame' and
			     $title->tc_video_bitrate_range ) {
			     	if ($attr eq 'tc_start_frame') {
					$title->set_tc_start_frame($_[0]->get_text);
				} else {
					$title->set_tc_end_frame($_[0]->get_text);
				}
				$self->calc_video_bitrate;
				$self->init_transcode_values;
			}

			1;
		}, "set_$attr");
	}

	$widgets->{tc_video_codec}->signal_connect ("focus-out-event", sub {
		my ($widget) = @_;
		return 1 if not $self->selected_title;
		return 1 if $self->in_transcode_init;
		$self->selected_title->calc_video_bitrate;
		$self->init_transcode_values;
		1;
	});
	
	# radio button signals

	foreach my $attr (qw ( tc_multipass tc_preview tc_psu_core )) {
		$widgets->{$attr."_yes"}->signal_connect ( "clicked", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->$method(1);
			1;
		}, "set_$attr");
		$widgets->{$attr."_no"}->signal_connect ( "clicked", sub {
			my ($widget, $method) = @_;
			return 1 if not $self->selected_title;
			return 1 if $self->in_transcode_init;
			$self->selected_title->$method(0);
			1;
		}, "set_$attr");
	}

	$self->transcode_widgets->{tc_exit_afterwards}->signal_connect (
		"toggled", sub {
			my $title = $self->selected_title;
			return 1 if not $title;
			return 1 if $self->in_transcode_init;
			$title->set_tc_exit_afterwards ($_[0]->active);
			1;
		}
	);

	return $vbox;
}

sub create_container_options {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("Container options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 1, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Container Format
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target format");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$hsize_group->add ($hbox);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_usize(90,undef);
	$popup->set_menu($popup_menu);

	foreach my $key ( sort keys %Video::DVDRip::container_formats ) {
		$item = Gtk::MenuItem->new (
			$Video::DVDRip::container_formats{$key}
		);
		$item->show;
		$popup_menu->append($item);
		
		my $sensitive = 1;
		$sensitive = 0 if $key eq 'vcd' and not $self->has("mjpegtools");
		$sensitive = 0 if $key eq 'ogg' and not $self->has("ogmtools");
		
		$item->set_sensitive($sensitive);

		$item->signal_connect (
			"activate", sub {
				my $title = $self->selected_title;
				return 1 if not $title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_container($key);
				$self->init_video_codec_combo;
				$self->calc_video_bitrate;
				$self->init_audio_values;
				$self->init_transcode_values;

				1;
			}, $key
		) if $sensitive;
	}
	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->transcode_widgets->{tc_container_popup} = $popup;

	return $frame;
}

sub create_video_options {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new ("Video options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 6, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Video Codec
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video codec");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new (0, 20);
	$hbox->show;

	$entry = Gtk::Combo->new;
	$entry->show;
#	$entry->set_popdown_strings ("SVCD","VCD","divx4","divx5","xvid","xvidcvs","ffmpeg","fame","af6");
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_codec} = $entry->entry;
	$self->transcode_widgets->{tc_video_codec_combo} = $entry;

	# AF6 Codec
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("af6/ffmpeg codec");
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
	$label = Gtk::Label->new ("Video framerate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedCombo->new(
		is_number => 1,
		may_empty => 1,
		may_fractional => 1,
	);
	$entry->show;
	$entry->set_popdown_strings ("25", "23.976", "29.97");
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	
	$label = Gtk::Label->new("fps");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_framerate} = $entry->entry;

	# Enable DivX Multipass Encoding
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("2-pass encoding");
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

	# Deinterlace
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Deinterlace mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize (170, undef);

	foreach my $key ( sort keys %Video::DVDRip::deinterlace_filters ) {
		$item = Gtk::MenuItem->new (
			$Video::DVDRip::deinterlace_filters{$key}
		);
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
	
	$hbox = Gtk::HBox->new;
	$hbox->show,
	$hbox->pack_start ($popup, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_deinterlace_popup} = $popup;

	# Filters
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Filters");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$button = Gtk::Button->new ("  Configure filters & preview...  ");
	$button->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($button, 0, 1, 0);
	$button->signal_connect ( "clicked", sub { $self->transcode_filters } );

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	if ( $self->version ("transcode") < 603 ) {
		$button->set_sensitive(0);
		$button->child->set (" Needs transcode 0.6.3 ");
	}

	return $frame;
}

sub create_video_bitrate_calc {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("Video bitrate calculation");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 3, 3, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Target Media
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target media");
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
	$popup->set_usize (65,undef);
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
				my $title = $self->selected_title;
				return 1 if not $title;
				return 1 if $self->in_transcode_init;
				$title->set_tc_disc_cnt($key);
				$title->set_tc_target_size(
					int($key * $title->tc_disc_size)
				);
				$self->transcode_widgets
				     ->{tc_target_size}
				     ->set_text ($title->tc_target_size);
			}, $key
		);
	}
	$hbox->pack_start($popup, 0, 1, 0);
	
	$self->transcode_widgets->{tc_disc_cnt_popup} = $popup;

	$label = Gtk::Label->new ("x");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Video::DVDRip::CheckedCombo->new (
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_popdown_strings (650, 703, 800, 870);
	$entry->set_usize(60,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$entry->entry->signal_connect ("changed", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		return 1 if $self->in_transcode_init;
		$title->set_tc_disc_size ($_[0]->get_text);
		$title->set_tc_target_size(
			int ( $title->tc_disc_cnt *
			      $title->tc_disc_size ),
		);
		$self->transcode_widgets
		     ->{tc_target_size}
		     ->set_text ($title->tc_target_size);
		1;
	});

	$self->transcode_widgets->{tc_disc_size_combo} = $entry;

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach ($hbox, 1, 3, $row, $row+1, 'fill','expand',0,0);

	# Target Size
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target size");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_usize(65,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_target_size} = $entry;
	$self->transcode_widgets->{tc_target_size_label} = $label;

	
	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $checkbox = Gtk::CheckButton->new ("Use range");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 0, 1, 0);
	$checkbox->signal_connect (
		"clicked", sub {
			my $title = $self->selected_title;
			return 1 if not $title;
			return 1 if $self->in_transcode_init;
			$title->set_tc_video_bitrate_range($_[0]->active);
			$self->calc_video_bitrate;
			$self->init_transcode_values;
			1;
		}
	);
	
	$self->transcode_widgets->{tc_video_bitrate_range} = $checkbox;
	$table->attach_defaults ($hbox, 2, 3, $row, $row+1);
	
	# Video Bitrate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video bitrate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_usize(65,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("kbit/s");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{tc_video_bitrate} = $entry;

	$hbox = Gtk::HBox->new;
	$hbox->show;	
	my $checkbox = Gtk::CheckButton->new ("Manual");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 0, 1, 0);
	$checkbox->signal_connect (
		"clicked", sub {
			my $title = $self->selected_title;
			return 1 if not $title;
			return 1 if $self->in_transcode_init;
			$title->set_tc_video_bitrate_manual($_[0]->active);
			if ( not $title->tc_video_bitrate_manual ) {
				$self->calc_video_bitrate;
			}
			$self->init_transcode_values;
			1;
		}
	);
	
	$self->transcode_widgets->{tc_video_bitrate_manual} = $checkbox;

	$table->attach_defaults ($hbox, 2, 3, $row, $row+1);
	
	
	return $frame;
}

sub create_transcode_operate {
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
	$button = Gtk::Button->new_with_label ("Add to cluster");
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
	$frame = Gtk::Frame->new ("General options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 7, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# frame range
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Frame range");
	$label->set_line_wrap(1);
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$entry = Video::DVDRip::CheckedEntry->new ( undef,
		is_number => 1,
		may_empty => 1,
		cond => sub {
			my $start = $self->transcode_widgets->{tc_start_frame}->get_text;
			my $end   = $self->transcode_widgets->{tc_end_frame}->get_text;
			return 1 if $start eq '' or $end eq '';
			return $start < $end;
		},
	);
	$entry->show;
	$entry->set_usize (50,undef);
	
	$hbox->pack_start ($entry, 0, 1, 0);

	$self->transcode_widgets->{tc_start_frame} = $entry;

	$label = Gtk::Label->new(" - ");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Video::DVDRip::CheckedEntry->new ( undef,
		is_number => 1,
		may_empty => 1,
		cond => sub {
			my $start = $self->transcode_widgets->{tc_start_frame}->get_text;
			my $end   = $self->transcode_widgets->{tc_end_frame}->get_text;
			return 1 if $start eq '' or $end eq '';
			return $start < $end;
		},
	);
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
	$entry = Video::DVDRip::CheckedCombo->new (
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 1,
	);
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
	$label = Gtk::Label->new ("Preview window");
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
	
	# Execute when finished

	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Execute afterwards");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(120,undef);
	$hbox->pack_start($entry, 1, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->transcode_widgets->{tc_execute_afterwards} = $entry;

	my $checkbox = Gtk::CheckButton->new ("And exit");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 1, 1, 0);
	$self->transcode_widgets->{tc_exit_afterwards} = $checkbox;

	return $frame;
}

sub create_calculated_storage {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new ("Calculated storage");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 4, 3, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Video
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video size");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$label->set_justify("right");
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_video} = $label;

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	# Audio
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Non video size");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("100");
	$label->show;
	$label->set_justify("right");
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_audio} = $label;

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	# Separator
	++$row;
	my $sep = Gtk::HSeparator->new;
	$sep->show;
	$table->attach_defaults ($sep, 0, 2, $row, $row+1);

	# Sum
	++$row;
	$label = Gtk::Label->new ("Total size");
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
	$label->set_justify("right");
	$hbox->pack_start($label, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->transcode_widgets->{label_size_total} = $label;

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	# details button
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("   ");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$button = Gtk::Button->new (" Show details... ");
	$button->show;
	$hbox->pack_start($button, 0, 1, 0);

	$table->attach_defaults ($hbox, 2, 3, $row, $row+1);

	$button->signal_connect ("clicked", sub { $self->show_calc_details } );

	return $frame;
}

sub init_transcode_values {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($no_audio, $no_codec_combo) = @par{'no_audio','no_codec_combo'};

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	return 1 if not defined $widgets->{tc_video_codec};

	$self->set_in_transcode_init(1);

	foreach my $attr (qw ( tc_options tc_nice
			       tc_video_af6_codec tc_video_bitrate
			       tc_video_framerate tc_target_size
			       tc_start_frame tc_end_frame
			       tc_execute_afterwards )) {
		$widgets->{$attr}->set_text ($self->selected_title->$attr());
	}

	my $chapter_mode    = $title->tc_use_chapter_mode;
	my $multipass       = $title->tc_multipass;
	my $deinterlace     = $title->tc_deinterlace;
	my $anti_alias      = $title->tc_anti_alias;
	my $preview	    = $title->tc_preview;
	my $video_codec     = $title->tc_video_codec;
	my $psu_core        = $title->tc_psu_core;
	my $exit_afterwards = $title->tc_exit_afterwards;
	my $container 	    = $title->tc_container;

	my $disc_cnt        = $title->tc_disc_cnt;
	my $disc_size       = $title->tc_disc_size;

	$widgets->{tc_multipass_yes}->set_active($multipass);
	$widgets->{tc_multipass_no}->set_active(!$multipass);

	$deinterlace = 4 if $deinterlace eq '32detect';
	$deinterlace = 5 if $deinterlace eq 'smart';

	$widgets->{tc_deinterlace_popup}->set_history ($deinterlace);
#	$widgets->{tc_anti_alias_popup}->set_history ($anti_alias);

	$widgets->{tc_disc_cnt_popup}->set_history ($disc_cnt-1);
	$widgets->{tc_disc_size_combo}->entry->set_text ($disc_size);

	$widgets->{tc_preview_yes}->set_active($preview);
	$widgets->{tc_preview_no}->set_active(!$preview);

	$widgets->{tc_psu_core_yes}->set_active($psu_core);
	$widgets->{tc_psu_core_no}->set_active(!$psu_core);

	$widgets->{tc_exit_afterwards}->set_active($exit_afterwards);

	if ( $video_codec eq 'SVCD' or $video_codec eq 'VCD' ) {
		$self->switch_to_mpeg_encoding;
	} else {
		$self->switch_to_divx_encoding;
	}

	$container = $container eq 'avi' ? 0 :
		     $container eq 'ogg' ? 1 : 2;

	$widgets->{tc_container_popup}->set_history($container);

	$self->set_in_transcode_init(0);

	if ( not $no_audio ) {
		$self->init_audio_values;
		$self->fill_target_audio_popup;
	}

	if ( not $no_codec_combo ) {
		$self->init_video_codec_combo;
	}

	if ( $title->tc_video_bitrate_manual ) {
		$widgets->{tc_video_bitrate_manual}->set_active(1);
		$widgets->{tc_video_bitrate}->set_sensitive(1);
	} else {
		$widgets->{tc_video_bitrate_manual}->set_active(0);
		$widgets->{tc_video_bitrate}->set_sensitive(0);
	}

	if ( $title->tc_video_bitrate_range ) {
		$widgets->{tc_video_bitrate_range}->set_active(1);
	} else {
		$widgets->{tc_video_bitrate_range}->set_active(0);
	}
	
	$self->update_storage_labels;

	1;
}

sub switch_to_mpeg_encoding {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	foreach my $attr ( qw ( tc_video_af6_codec tc_multipass_yes
				tc_multipass_no) ) {
		$widgets->{$attr}->set_sensitive(0);
	}

	my $video_codec = $title->tc_video_codec;

	$widgets->{avisplit_button}->set_sensitive(0);
	$widgets->{cluster_button}->set_sensitive(0);
	$widgets->{view_avi_button}->child->set("View MPEG");

	$_->hide foreach @{$widgets->{tc_mpeg_hide}};

	1;
}

sub switch_to_divx_encoding {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	foreach my $attr ( qw ( tc_video_af6_codec tc_multipass_yes
				tc_multipass_no) ) {
		$widgets->{$attr}->set_sensitive(1);
	}

	$widgets->{avisplit_button}->set_sensitive(1);
	$widgets->{cluster_button}->set_sensitive(1);

	if ( $title->is_ogg ) {
		$widgets->{view_avi_button}->child->set("View OGG");
		$widgets->{avisplit_button}->child->set("Split OGG");
	} else {
		$widgets->{view_avi_button}->child->set("View AVI");
		$widgets->{avisplit_button}->child->set("Split AVI");
	}

	1;
}

sub init_video_codec_combo {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $in_init = $self->in_transcode_init;
	$self->set_in_transcode_init(1);

	my $widgets = $self->transcode_widgets;

	if ( $title->tc_container eq 'vcd' ) {
		$widgets->{tc_video_codec_combo}
			->set_popdown_strings( "SVCD", "VCD" );
	} else {
		$widgets->{tc_video_codec_combo}
			->set_popdown_strings( "divx4","divx5","xvid","xvidcvs","ffmpeg","fame","af6" );
	}

	$widgets->{tc_video_codec}->set_text($title->tc_video_codec);

	$self->set_in_transcode_init($in_init);

	1;
}

sub calc_video_bitrate {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;
	
	$title->calc_video_bitrate;
	$self->transcode_widgets->{tc_video_bitrate}->set_text($title->tc_video_bitrate);
	
	1;
}

sub update_storage_labels {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $bc = Video::DVDRip::BitrateCalc->new (
		title => $title,
	);
	$bc->calculate_video_bitrate;

	my $video_label = $self->transcode_widgets->{label_size_video};
	my $audio_label = $self->transcode_widgets->{label_size_audio};
	my $total_label = $self->transcode_widgets->{label_size_total};

	$video_label->set_text(sprintf("%.2f",$bc->video_size));
	$audio_label->set_text(sprintf("%.2f",$bc->non_video_size));
	$total_label->set_text(sprintf("%.2f",$bc->video_size + $bc->non_video_size));

	my $bc_window = eval { $self->comp('bitrate_calc') };
	$bc_window->init_calc_list if $bc_window;

	1;
}

sub transcode {
	my $self = shift;
	my %par = @_;
	my ($split, $subtitle_test) = @par{'split','subtitle_test'};

	return 1 if $self->comp('progress')->is_active;

	my $title    = $self->selected_title;

	return 1 if not $title;

	my $chapters = $title->get_chapters;

	Video::DVDRip::InfoFile->new (
		title    => $title,
		filename => $title->info_file,
	)->write;

	my $mpeg = $title->tc_video_codec =~ /^S?VCD$/;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

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

	if ( $title->tc_psu_core and
	     $title->project->rip_mode ne 'rip' ) {
		$self->message_window (
			message => "PSU core only available for ripped DVD's."
		);
		return 1;
	}

	if ( $title->tc_use_chapter_mode and not @{$chapters} ) {
		$self->message_window (
			message => "No chapters selected."
		);
		return 1;
	}

	if ( $title->tc_use_chapter_mode and $split ) {
		$self->message_window (
			message => "Splitting AVI files in\n".
				   "chapter mode makes no sense."
		);
		return 1;
	}

	if ( $title->get_first_audio_track == -1 ) {
		$self->message_window (
			message => "WARNING: no target audio track #0"
		);
	}

	if ( keys %{$title->get_additional_audio_tracks} ) {
		if ( $title->tc_video_codec eq 'VCD' ) {
			$self->message_window (
				message =>
					"Having more than one audio track ".
					"isn't possible on a VCD."
			);
			return 1;
		}
		if ( $title->tc_video_codec eq 'SVCD' and
		     keys %{$title->get_additional_audio_tracks} > 1 ) {
			$self->message_window (
				message =>
					"WARNING: Having more than two audio tracks\n".
					"on a SVCD is not standard conform. You may\n".
					"encounter problems on hardware players."
			);
		}
	}

	my $svcd_warning;
	if ( $svcd_warning = $title->check_svcd_geometry ) {
		$self->message_window (
			message =>
				"WARNING: $svcd_warning\n".
				"You better cancel now and select the appropriate\n".
				"preset on the Clip & Zoom page.",
		);
	}

	return $self->transcode_multipass_with_vbr_audio (
		split         => $split,
		subtitle_test => $subtitle_test
	) if not $subtitle_test
	     and $title->has_vbr_audio
	     and $title->tc_multipass;

	my $nr;
	my $job;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;

	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::TranscodeVideo->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_chapter ($chapter);
		$job->set_subtitle_test ($subtitle_test);
		$job->set_split ($split);

		if ( not $subtitle_test and $title->tc_multipass ) {
			$job->set_pass (1);
			$last_job = $exec->add_job ( job => $job );

			$job = Video::DVDRip::Job::TranscodeVideo->new (
				nr            => ++$nr,
				title         => $title,
			);
			$job->set_pass (2);
			$job->set_split ($split);
			$job->set_chapter ($chapter);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$last_job = $exec->add_job ( job => $job );
	
		} else {
			$job->set_single_pass(1);
			$last_job = $exec->add_job ( job => $job );
		}

		if ( $title->tc_container eq 'ogg' ) {
			$job = Video::DVDRip::Job::MergeAudio->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_vob_nr ( $title->get_first_audio_track );
			$job->set_avi_nr ( 0 );
			$job->set_chapter ($chapter);
			$job->set_subtitle_test ($subtitle_test);
			$last_job = $exec->add_job ( job => $job );
		}

		if ( not $subtitle_test ) {
			my $add_audio_tracks = $title->get_additional_audio_tracks;
			if ( keys %{$add_audio_tracks} ) {
				my ($avi_nr, $vob_nr);
				foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
					$vob_nr = $add_audio_tracks->{$avi_nr};

					$job = Video::DVDRip::Job::TranscodeAudio->new (
						nr    => ++$nr,
						title => $title,
					);
					$job->set_vob_nr ( $vob_nr );
					$job->set_avi_nr ( $avi_nr );
					$job->set_chapter ($chapter);
					$last_job = $exec->add_job ( job => $job );

					if ( not $mpeg ) {
						$job = Video::DVDRip::Job::MergeAudio->new (
							nr    => ++$nr,
							title => $title,
						);
						$job->set_vob_nr ( $vob_nr );
						$job->set_avi_nr ( $avi_nr );
						$job->set_chapter ($chapter);
						$last_job = $exec->add_job ( job => $job );
					}
				}
			}
		}

		if ( $mpeg ) {
			$job = Video::DVDRip::Job::Mplex->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_chapter ($chapter);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$job->set_subtitle_test ($subtitle_test);
			$last_job = $exec->add_job ( job => $job );
		}

		if ( not $subtitle_test and $split and not $mpeg ) {
			$job = Video::DVDRip::Job::Split->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$last_job = $exec->add_job ( job => $job );
		}
	}

	if ( $split ) {
		$last_job->set_cb_finished ( sub {
			$self->create_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	} else {
		$last_job->set_cb_finished ( sub {
			$self->create_non_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	}

	$exec->set_cb_finished (sub {
		return 1 if $exec->cancelled or $exec->errors_occured;
		return 1 if $subtitle_test;
		if ( $title->tc_execute_afterwards =~ /\S/ ) {
			system ("(".$title->tc_execute_afterwards.") &");
		}
		if ( $title->tc_exit_afterwards ) {
			$title->project->save
				if $title->tc_exit_afterwards ne 'dont_save';
			$self->comp('main')->exit_program (
				force => ($title->tc_exit_afterwards eq 'dont_save')
			);
		}
		1;
	});

	$exec->execute_jobs;

	1;
}

sub transcode_multipass_with_vbr_audio {
	my $self = shift;
	my %par = @_;
	my ($split) = @par{'split'};

	$self->log ("This title is transcoded with vbr audio ".
		    "and video bitrate optimization.");

	my $title    = $self->selected_title;
	my $chapters = $title->get_chapters;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	my $bc = Video::DVDRip::BitrateCalc->new (
		title => $title,
	);

	my $nr;
	my $job;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;

	# 1. encode additional audio tracks
	foreach my $chapter ( @{$chapters} ) {
		my $add_audio_tracks = $title->get_additional_audio_tracks;
		if ( keys %{$add_audio_tracks} ) {
			my ($avi_nr, $vob_nr);
			foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
				$vob_nr = $add_audio_tracks->{$avi_nr};
				$job = Video::DVDRip::Job::TranscodeAudio->new (
					nr    => ++$nr,
					title => $title,
				);
				$job->set_vob_nr  ( $vob_nr  );
				$job->set_avi_nr  ( $avi_nr  );
				$job->set_chapter ( $chapter );
				$job->set_bc      ( $bc      );
				$last_job = $exec->add_job ( job => $job );
			}
		}
	}
	
	# 2. 1st pass of Video + 1st Audio track
	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::TranscodeVideo->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_bc ($bc);
		$job->set_pass (1);
		$job->set_chapter ($chapter);
		$job->set_depends_on_jobs ( [ $last_job ] ) if $last_job;
		$last_job = $exec->add_job ( job => $job );
	}
	
	# 3. after 1st pass: calculate video bitrate (real audio size known)
	$last_job->set_cb_finished (sub {
		$title->set_tc_video_bitrate ( $bc->calculate_video_bitrate );
		$self->log ("Adjusted video bitrate to ".
			    $title->tc_video_bitrate.
			    " after vbr audio transcoding");
		$self->init_transcode_values;
		1;
	});
	
	# 4. 2nd pass Video and merging
	foreach my $chapter ( @{$chapters} ) {
		# transcode video 2nd pass
		$job = Video::DVDRip::Job::TranscodeVideo->new (
			nr            => ++$nr,
			title         => $title,
		);
		$job->set_pass (2);
		$job->set_chapter ($chapter);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$last_job = $exec->add_job ( job => $job );

		# merge 1st audio track
		$job = Video::DVDRip::Job::MergeAudio->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_vob_nr ( $title->get_first_audio_track );
		$job->set_avi_nr ( 0 );
		$job->set_chapter ($chapter);
		$last_job = $exec->add_job ( job => $job );

		# merge add. audio tracks
		my ($avi_nr, $vob_nr);
		my $add_audio_tracks = $title->get_additional_audio_tracks;
		foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
			$vob_nr = $add_audio_tracks->{$avi_nr};

			$job = Video::DVDRip::Job::MergeAudio->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_vob_nr ( $vob_nr );
			$job->set_avi_nr ( $avi_nr );
			$job->set_chapter ($chapter);
			$last_job = $exec->add_job ( job => $job );
		}

	}

	# 5. optional splitting (non chapter mode only)
	if ( $split ) {
		$job = Video::DVDRip::Job::Split->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$last_job = $exec->add_job ( job => $job );

		$last_job->set_cb_finished ( sub {
			$self->create_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	} else {
		$last_job->set_cb_finished ( sub {
			$self->create_non_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	}

	# 6. execute afterwards stuff
	$exec->set_cb_finished (sub {
		return 1 if $exec->cancelled or $exec->errors_occured;
		if ( $title->tc_execute_afterwards =~ /\S/ ) {
			system ("(".$title->tc_execute_afterwards.") &");
		}
		if ( $title->tc_exit_afterwards ) {
			$title->project->save
				if $title->tc_exit_afterwards ne 'dont_save';
			$self->comp('main')->exit_program (
				force => ($title->tc_exit_afterwards eq 'dont_save')
			);
		}
		1;
	});

	$exec->execute_jobs;

	1;
}

sub avisplit {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;
	
	if ( $title->tc_use_chapter_mode ) {
		$self->message_window (
			message => "Splitting an AVI file in\n".
				   "Chapter Mode makes no sense."
		);
		return 1;
	}

	if ( not -f $title->avi_file ) {
		$self->message_window (
			message => "You first have to transcode this title."
		);
		return 1;
	}

	my $nr;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;
	my $job  = Video::DVDRip::Job::Split->new (
		nr    => ++$nr,
		title => $title,
	);

	$last_job = $exec->add_job ( job => $job );

	$last_job->set_cb_finished ( sub {
		$self->create_splitted_vobsub (
			exec     => $exec,
			last_job => $last_job
		);
		1;
	} );

	$exec->execute_jobs;

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

sub scan_rescale_volume {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if $self->comp('progress')->is_active;
	return 1 if not $title;

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	my $job;
	my $nr;
        my $chapter_count = 0;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new (
		cb_finished => sub { $self->init_transcode_values }
	);

	my $chapters = $title->get_chapters;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::ScanVolume->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_chapter ($chapter);
		$job->set_count   ($chapter_count++);
		$last_job = $exec->add_job ( job => $job );
	}

	$exec->execute_jobs;

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

	if ( $title->tc_psu_core ) {
		$self->message_window (
			message => "PSU core mode currently not supported"
		);
		return 1;
	}

	if ( $title->project->rip_mode ne 'rip' ) {
		$self->message_window (
			message => "Cluster mode is only supported\nfor ripped DVD's."
		);
		return 1;
	}


	if ( not $title->is_ripped ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	if ( $title->get_first_audio_track < 0 ) {
		$self->message_window (
			message => "You have no target audio track selected."
		);
		return 1;
	}

	if ( $title->tc_container eq 'vcd' ) {
		$self->message_window (
			message => "(S)VCD is not supported for cluster mode."
		);
		return 1;
	}

	# calculate program stream units, if not already done
	$title->calc_program_stream_units
		if not $title->program_stream_units or
		   not @{$title->program_stream_units};

	if ( $title->is_ogg and @{$title->program_stream_units} > 1 ) {
		$self->message_window (
			message =>
				"Cluster mode supports OGG/Vorbis only for movies with\n".
				"one PSU. Unfortunetaly this title has ".
				@{$title->program_stream_units}." PSU's.\n\n".
				"Cluster mode support for such titles will be added\n".
				"as soon as ogmtools handle concatenating\n".
				"several OGG files. Stay tuned."
		);
		return 1;
	}

	$self->comp('main')->cluster_control;
	
	my $cluster = eval { $self->comp('cluster') };
	return if not $cluster;

	$cluster->add_project (
		project  => $self->project,
		title_nr => $title->nr,
	);
	
	1;
}

sub show_calc_details {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	require Video::DVDRip::GUI::BitrateCalc;

	my $calc_details = Video::DVDRip::GUI::BitrateCalc->new;
	$calc_details->open_window;

	1;	
}

sub create_wav {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $nr;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;

	my $chapters = $title->get_chapters;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	my $job;
	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::CreateWav->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_chapter ( $chapter );
		$last_job = $exec->add_job ( job => $job );
	}

	$exec->execute_jobs;

	1;
}

sub transcode_filters {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	require Video::DVDRip::GUI::Filters;

	my $filters = Video::DVDRip::GUI::Filters->new;
	$filters->open_window;

	1;	
}

1;
