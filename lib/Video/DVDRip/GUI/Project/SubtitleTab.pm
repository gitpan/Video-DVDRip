# $Id: SubtitleTab.pm,v 1.14.2.1 2003/02/11 22:17:05 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

use File::Path;
use File::Basename;

my $TABLE_SPACING = 5;
my $ENTRY_SIZE = 60;

sub subtitle_widgets		{ shift->{subtitle_widgets} 		}
sub set_subtitle_widgets	{ shift->{subtitle_widgets}	= $_[1]	}

#------------------------------------------------------------------------
# Build Subtitle Tab
#------------------------------------------------------------------------

sub create_subtitle_tab {
	my $self = shift; $self->trace_in;

	$self->set_subtitle_widgets ({});

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;

	# Left HSize Group
	my $left_hsize_group = Video::DVDRip::GUI::MinSizeGroup->new (
		type => 'h',
		debug => 0,
	);
	
	# Frame with Selected Title
	my $selected_title = $self->create_selected_title;
	$vbox->pack_start ( $selected_title, 0, 1, 0);

	# Build Frames
	my $select = $self->create_subtitle_select (
		hsize_group => $left_hsize_group
	);
	my $preview = $self->create_subtitle_preview (
		hsize_group => $left_hsize_group
	);
	my $render = $self->create_subtitle_render (
		hsize_group => $left_hsize_group
	);
	my $vobsub = $self->create_subtitle_vobsub (
		hsize_group => $left_hsize_group
	);

	# Put frames into table
	my $table = Gtk::Table->new ( 4, 1, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$vbox->pack_start ($table, 0, 1, 0);

	$table->attach_defaults ($select, 	0, 1, 0, 1);
	$table->attach_defaults ($preview, 	0, 1, 1, 2);
	$table->attach_defaults ($render, 	0, 1, 2, 3);
	$table->attach_defaults ($vobsub, 	0, 1, 3, 4);

	return $vbox;
}

sub create_subtitle_select {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->subtitle_widgets;
	$widgets->{select} = {};
	$widgets = $widgets->{select};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new ("Subtitle selection");
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

	$widgets->{frame} = $frame;

	# Select subtitle
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Select subtitle");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$hsize_group->add ($hbox);

	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_usize (150,undef);
	$popup->set_menu($popup_menu);
	$item = Gtk::MenuItem->new ("No subtitles available");
	$item->show;
	$popup_menu->append($item);
	$popup->set_history(0);
	$hbox->pack_start($popup, 0, 1, 0);

	$widgets->{selection_popup} = $popup;

	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	my $selected = "Activated:";

	if ( $selected eq 'Activated:' ) {
		$selected = "subtitle2pgm is missing or too old"
			if not $self->has("subtitle2pgm");
	}

	if ( $selected ne 'Activated:' ) {
		$widgets->{selection_popup}->hide;
	}

	$label = Gtk::Label->new ("$selected");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	
	$label = Gtk::Label->new ("");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$widgets->{selection_label} = $label;

	return $frame;
}

sub create_subtitle_preview {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->subtitle_widgets;
	$widgets->{preview} = {};
	$widgets = $widgets->{preview};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button, $sw);

	# Frame
	$frame = Gtk::Frame->new ("Preview");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 2, 1, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	$widgets->{frame} = $frame;

	# Preview Button and parameters
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$button = Gtk::Button->new ("    Grab    ");
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	$widgets->{preview_button} = $button;

	$button->signal_connect ("clicked", sub {
		$self->grab_subtitle_preview_images;
	});

	$entry = Video::DVDRip::CheckedCombo->new (
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_popdown_strings (1, 3, 5, 10);
	$entry->set_usize(60,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$widgets->{tc_preview_img_cnt} = $entry->entry;
	$entry->entry->signal_connect ("changed", sub {
		return if $self->in_transcode_init;

		my $subtitle =  $self->selected_title->selected_subtitle;
		$subtitle->set_tc_preview_img_cnt ( $_[0]->get_text );

		my $test_image_cnt = $self->subtitle_widgets->{render}->{tc_test_image_cnt};
		return 1 if not $test_image_cnt;

		$test_image_cnt->set_is_max  ( $_[0]->get_text );
		$test_image_cnt->set_old_val ( $_[0]->get_text );
		$test_image_cnt->check_value;

		$subtitle->set_tc_test_image_cnt ( $test_image_cnt->get_text );

		1;
	});

	$label = Gtk::Label->new ("  image(s), starting at  ");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_frame_or_timecode => 1,
		may_fractional       => 0,
		may_empty            => 0,
	);
	$entry->show;
	$entry->set_usize (80, undef);
	$hbox->pack_start ($entry, 0, 1, 0);
	$widgets->{tc_preview_timecode} = $entry;
	$entry->signal_connect ("changed", sub {
		return if $self->in_transcode_init;
		$self->selected_title
		     ->selected_subtitle
		     ->set_tc_preview_timecode ( $_[0]->get_text );
	});

	$label = Gtk::Label->new (" (timecode nn:nn:nn or frame number) ");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	# Preview images area
	++$row;
	$sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_usize ($self->config('main_window_width')-50, 150);
	$sw->set_policy( 'automatic', 'automatic' );
	
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$sw->add_with_viewport( $hbox );
	$table->attach ($sw, 0, 1, $row, $row+1, 'fill','fill',0,0);

	$widgets->{preview_images_sw} = $sw;
	$widgets->{preview_images_hbox} = $hbox;

	return $frame;
}

sub create_subtitle_render {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->subtitle_widgets;
	$widgets->{render} = {};
	$widgets = $widgets->{render};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $checkbox, $button);

	# Frame
	$frame = Gtk::Frame->new ("Render subtitle on movie");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 4, 7, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING + 4 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	$widgets->{frame} = $frame;

	#-------------------------------------------------------------
	# Activate this subtitle
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Activate this subtitle");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$checkbox = Gtk::CheckButton->new ("for rendering");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_render} = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return 1 if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		my $subtitle = $title->selected_subtitle;
		return if not $subtitle;
		$subtitle->set_tc_render ($_[0]->active);
		$self->set_render_vobsub_sensitive;
		$self->set_selected_label;
		1;
	});

	# Vertical offset
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Vertical offset");
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
		may_negative   => 1,
	);
	$entry->set_usize($ENTRY_SIZE,undef);
	$entry->show;
	$hbox->pack_start ($entry, 0, 1, 0);
	$label = Gtk::Label->new ("rows");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_vertical_offset_label} = $label;
	$widgets->{tc_vertical_offset} = $entry;

	# Time shift
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Time shift");
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
		may_negative   => 1,
	);
	$entry->set_usize($ENTRY_SIZE,undef);
	$entry->show;
	$hbox->pack_start ($entry, 0, 1, 0);
	$label = Gtk::Label->new ("ms");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_time_shift_label} = $label;
	$widgets->{tc_time_shift} = $entry;

	# Antialiasing / Postprocessing
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$checkbox = Gtk::CheckButton->new ("Postprocessing");
	$checkbox->show;
	$hbox->pack_start($checkbox, 0, 1, 0);

	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_postprocess}  = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return 1 if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		my $subtitle = $title->selected_subtitle;
		return if not $subtitle;
		$subtitle->set_tc_postprocess ($_[0]->active);
		1;
	});

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$checkbox = Gtk::CheckButton->new ("Antialiasing");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 0, 1, 0);

	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_antialias} = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return 1 if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		my $subtitle = $title->selected_subtitle;
		return if not $subtitle;
		$subtitle->set_tc_antialias ($_[0]->active);
		1;
	});

	#-------------------------------------------------------------
	# Enable color manipulation
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Colors");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$checkbox = Gtk::CheckButton->new ("Enable manipulation");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 0, 1, 0);

	$table->attach ($hbox, 3, 5, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_color_manip_label} = $label;
	$widgets->{tc_color_manip} = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return 1 if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		my $subtitle = $title->selected_subtitle;
		return if not $subtitle;
		$subtitle->set_tc_color_manip ($_[0]->active);
		$self->set_render_vobsub_sensitive;
		1;
	});

	# Color A / B
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Gray A/B");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		is_min         => 0,
		is_max	       => 255,
		may_fractional => 0,
		may_empty      => 0,
		may_negative   => 0,
	);
	$entry->show;
	$entry->set_usize($ENTRY_SIZE,undef);
	$hbox->pack_start ($entry, 0, 1, 0);

	$widgets->{tc_color_a_label} = $label;
	$widgets->{tc_color_a} = $entry;

	$table->attach ($hbox, 3, 4, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		is_min         => 0,
		is_max	       => 255,
		may_fractional => 0,
		may_empty      => 0,
		may_negative   => 0,
	);
	$entry->show;
	$entry->set_usize($ENTRY_SIZE,undef);
	$hbox->pack_start ($entry, 0, 1, 0);

	$widgets->{tc_color_b_label} = $label;
	$widgets->{tc_color_b} = $entry;

	$table->attach ($hbox, 4, 5, $row, $row+1, 'fill','expand',0,0);

	# Assign Color A / B
	++$row ;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Index A/B");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize($ENTRY_SIZE,undef);

	%popup_entries = (
		0 => 0,
		1 => 1,
		2 => 2,
		3 => 3,
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				return if $self->in_transcode_init;
				my $subtitle = $self->selected_title
						    ->selected_subtitle;
				$subtitle->set_tc_assign_color_a($key);
				1;
			}
		);
	}
	$hbox->pack_start($popup, 1, 1, 0);

	$widgets->{tc_assign_color_a_label} = $label;
	$widgets->{tc_assign_color_a} = $popup;

	$table->attach ($hbox, 3, 4, $row, $row+1, 'fill','expand',0,0);

	# Assign Color B
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize($ENTRY_SIZE,undef);

	%popup_entries = (
		0 => 0,
		1 => 1,
		2 => 2,
		3 => 3,
	);

	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				return if $self->in_transcode_init;
				my $subtitle = $self->selected_title
						    ->selected_subtitle;
				$subtitle->set_tc_assign_color_b($key);
				1;
			}
		);
	}
	$hbox->pack_start($popup, 1, 1, 0);

	$widgets->{tc_assign_color_b_label} = $label;
	$widgets->{tc_assign_color_b} = $popup;

	$table->attach ($hbox, 4, 5, $row, $row+1, 'fill','expand',0,0);

	#-------------------------------------------------------------
	# Suggest buttons

	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Suggest");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$button = Gtk::Button->new (" Values for letterbox ");
	$button->show;
	$hbox->pack_start ($button, 1, 1, 0);
	$table->attach ($hbox, 3, 5, $row, $row+1, 'fill','expand',0,0);

	$widgets->{suggest_black_bars_label} = $label;
	$widgets->{suggest_black_bars_button} = $button;

	$button->signal_connect ("clicked", sub {
		$self->suggest_render_black_bars;
	} );

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$button = Gtk::Button->new (" Values for full size movie ");
	$button->show;
	$hbox->pack_start ($button, 1, 1, 0);
	$table->attach ($hbox, 5, 7, $row, $row+1, 'fill','expand',0,0);

	$widgets->{suggest_full_size_label} = $label;
	$widgets->{suggest_full_size_button} = $button;

	$button->signal_connect ("clicked", sub {
		$self->suggest_render_full_size;
	} );

	#-------------------------------------------------------------
	# Test image count
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Test image count");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 5, 6, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_usize($ENTRY_SIZE,undef);
	$hbox->pack_start ($entry, 0, 1, 0);

	$table->attach ($hbox, 6, 7, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_test_image_cnt_label} = $label;
	$widgets->{tc_test_image_cnt} = $entry;

	# Test transcode
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Test transcode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 5, 6, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$button = Gtk::Button->new (" Transcode ");
	$button->set_usize (80, undef);
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	$table->attach ($hbox, 6, 7, $row, $row+1, 'fill','expand',0,0);

	$widgets->{test_transcode_button_label} = $label;
	$widgets->{test_transcode_button} = $button;

	$button->signal_connect ("clicked", sub {
		$self->subtitle_test_transcode
	} );

	# View test transcoding
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Test view");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 5, 6, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$button = Gtk::Button->new (" View ");
	$button->set_usize (80, undef);
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	$table->attach ($hbox, 6, 7, $row, $row+1, 'fill','expand',0,0);

	$widgets->{test_view_button_label} = $label;
	$widgets->{test_view_button} = $button;

	$button->signal_connect ("clicked", sub {
		$self->subtitle_test_view
	} );

	# connect signals ============================================
	
	foreach my $name ( qw ( tc_vertical_offset tc_time_shift tc_color_a
				tc_color_b tc_test_image_cnt ) ) {
		my $method = "set_$name";
		$widgets->{$name}->signal_connect ( "changed", sub {
			return if $self->in_transcode_init;
			my $subtitle = $self->selected_title->selected_subtitle;
			$subtitle->$method($_[0]->get_text);
			1;
		} );
	}

	return $frame;
}

sub create_subtitle_vobsub {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->subtitle_widgets;
	$widgets->{vobsub} = {};
	$widgets = $widgets->{vobsub};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button, $checkbox);

	# Frame
	$frame = Gtk::Frame->new ("Create vobsub file");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 2, 4, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING + 4 );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	$widgets->{frame} = $frame;

	# Create now
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Create now");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$button = Gtk::Button->new (" Create now ");
	$button->set_usize (80, undef);
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);
	$button->signal_connect ("clicked", sub { $self->create_vobsub_now } );

	$widgets->{create_now_button} = $button;

	$button = Gtk::Button->new (" View vobsub ");
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	$button->signal_connect ("clicked", sub { $self->view_vobsub } );

	$widgets->{view_vobsub_button} = $button;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("     Only useful for single-CD-rips.");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);

	# Create later
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Create later");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$checkbox = Gtk::CheckButton->new ("after transcoding");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("     This considers splitted files correctly.");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_vobsub} = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return 1 if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		my $subtitle = $title->selected_subtitle;
		return if not $subtitle;
		$subtitle->set_tc_vobsub ($_[0]->active);
		$self->set_render_vobsub_sensitive;
		$self->set_selected_label;
		1;
	});

	return $frame;
}

sub set_subtitle_sensitive {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $subtitles = $title->subtitles;
	my $widgets   = $self->subtitle_widgets;

	my $sensitive = 1;
	$sensitive = 0 if not $title->is_ripped or 
			  not $subtitles or keys %{$subtitles} == 0 or
			  not $self->has ("subtitle2pgm");



	foreach my $type ( "select", "preview", "vobsub", "render" ) {
		$widgets->{$type}->{frame}->set_sensitive($sensitive);
	}
	
	return $sensitive;
}

sub init_subtitle_values {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	$self->set_in_transcode_init (1);

	my $subtitles = $title->subtitles;
	my $widgets   = $self->subtitle_widgets;

	my $sensitive = $self->set_subtitle_sensitive;
	
	my %popup_entries;
	if ( $sensitive ) {
		foreach my $subtitle ( values %{$subtitles} ) {
			$popup_entries{$subtitle->id} =
				$subtitle->id." ".
				$subtitle->lang;
		}
	} else {
		%popup_entries = (
			-1 => $title->is_ripped ?
				"No subtitles available" :
				"Title isn't ripped"
		);
	}

	my $item;
	my $popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$widgets->{select}->{selection_popup}->set_menu($popup_menu);
	
	my $history = 0;
	my $i = 0;
	foreach my $key ( sort { $a <=> $b } keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				$self->select_subtitle ( id => $key );
			}, $key
		) if $key != -1;
		$history = $i if $key != -1 and
				 $title->selected_subtitle_id == $key;
		++$i;
	}

	$widgets->{select}->{selection_popup}->set_history( $history );
	$self->select_subtitle ( id => $title->selected_subtitle_id );

	$self->set_selected_label;

	$self->set_in_transcode_init (0);

	return 1;
}

sub set_selected_label {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->subtitle_widgets;

	my $selected_label;
	if ( $title->subtitles ) {
		foreach my $subtitle ( sort { $a->id <=> $b->id }
				       values %{$title->subtitles} ) {
			if ( $subtitle->tc_render ) {
				$selected_label .=
					$subtitle->id." ".$subtitle->lang." (render); ";
			} elsif ( $subtitle->tc_vobsub ) {
				$selected_label .=
					$subtitle->id." ".$subtitle->lang." (vobsub); ";
			}
		}
	}

	$selected_label =~ s/; $//;

	$selected_label ||= "No subtitles activated.";

	$widgets->{select}->{selection_label}->set($selected_label);

	1;
}

sub init_subtitle_specific_values {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $subtitle = $title->selected_subtitle;
	return 1 if not $subtitle;

	my $widgets = $self->subtitle_widgets;

	# Set subtitle specific options ==============================

	$self->set_in_transcode_init (1);
	
	$widgets->{render}->{tc_render}->set_active ( $subtitle->tc_render );
	$widgets->{vobsub}->{tc_vobsub}->set_active ( $subtitle->tc_vobsub );
	$widgets->{render}->{tc_color_manip}
			  ->set_active ( $subtitle->tc_color_manip );

	foreach my $name ( qw ( tc_vertical_offset tc_time_shift tc_color_a
				tc_color_b tc_test_image_cnt ) ) {
		$widgets->{render}->{$name}->set_text ( $subtitle->$name() );
	}

	$widgets->{render}->{tc_assign_color_a}->set_history (
		$subtitle->tc_assign_color_a
	);
	$widgets->{render}->{tc_assign_color_b}->set_history (
		$subtitle->tc_assign_color_b
	);

	$widgets->{render}->{tc_antialias}->set_active ($subtitle->tc_antialias);
	$widgets->{render}->{tc_postprocess}->set_active ($subtitle->tc_postprocess);
	$widgets->{render}->{tc_test_image_cnt}->set_is_max ( $subtitle->tc_preview_img_cnt );

	$self->set_in_transcode_init (0);

	1;
}

sub set_render_vobsub_sensitive {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;
	
	my $subtitle = $title->selected_subtitle;
	return 1 if not $subtitle;

	my $widgets = $self->subtitle_widgets;

	my %sensitive;
	if ( $subtitle->tc_render xor $subtitle->tc_vobsub ) {
		%sensitive = (
			render => $subtitle->tc_render,
			vobsub => $subtitle->tc_vobsub,
		);
	} else {
		%sensitive = (
			render => 1,
			vobsub => 1,
		);
	}

	if ( $title->get_render_subtitle and
	     $subtitle->id != $title->get_render_subtitle->id ) {
		$sensitive{render} = 0;
	}

	$sensitive{vobsub} = 0 if $title->tc_use_chapter_mode;
	$sensitive{render} = 0 if $title->project->rip_mode ne 'rip';

	foreach my $type ( "vobsub", "render" ) {
		$widgets->{$type}->{frame}->set_sensitive($sensitive{$type});
	}

	my $render_sensitive = $subtitle->tc_render;
	my $color_sensitive  = $render_sensitive & $subtitle->tc_color_manip;

	my ($name, $widget);
	while ( ($name, $widget) = each %{$widgets->{render}} ) {
		next if $name =~ /render|frame/;
		if ( $name =~ /color_[^m]/ ) {
			$widget->set_sensitive($color_sensitive);
		} else {
			$widget->set_sensitive($render_sensitive);
		}
	}

	1;
}

sub select_subtitle {
	my $self = shift;
	my %par= @_;
	my ($id) = @par{'id'};

	my $title = $self->selected_title;
	$title->set_selected_subtitle_id ( $id );

	$self->show_all_preview_images;
	$self->init_subtitle_specific_values;
	$self->set_render_vobsub_sensitive;
	
	my $widgets  = $self->subtitle_widgets;
	my $subtitle = $title->selected_subtitle;
	
	return 1 if not $subtitle;

	$widgets->{select}->{selection_popup}->set_sensitive(1);
	$widgets->{preview}->{tc_preview_img_cnt}->set_text( $subtitle->tc_preview_img_cnt );
	$widgets->{preview}->{tc_preview_timecode}->set_text( $subtitle->tc_preview_timecode );

	return 1;
}

sub grab_subtitle_preview_images {
	my $self = shift;
	my %par = @_;
	my ($force) = @par{'force'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;
	return 1 if not $title->selected_subtitle;

	if ( not $self->has ( "subtitle2pgm" ) ) {
		$self->message_window (
			message => "Sorry, you need subtitle2pgm for this to work."
		);
		return 1;
	}

	my $nr;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;
	my $job  = Video::DVDRip::Job::GrabSubtitleImages->new (
		nr    => ++$nr,
		title => $title,
	);

	$last_job = $exec->add_job ( job => $job );

	$exec->set_cb_finished (sub{
		$self->show_all_preview_images;
	});

	$exec->execute_jobs;

	1;
}

sub show_all_preview_images {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;
	
	my $widgets = $self->subtitle_widgets;

	my $hbox = $widgets->{preview}->{preview_images_hbox};
	my $sw   = $widgets->{preview}->{preview_images_sw};
	
	$sw->remove ($sw->children) if $sw->children;
	
	my $event_box = Gtk::EventBox->new;
	$event_box->show;
	my $style = $event_box->style->copy;
	$style->bg ('normal', $self->gdk_color('ffffff'));
	$event_box->set_style($style);
	
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->set_border_width(10);

	$widgets->{preview_images_hbox} = $hbox;

	$event_box->add ($hbox);
	$sw->add_with_viewport ($event_box);
	
	return if $title->selected_subtitle_id < 0;
	
	$title->selected_subtitle->reset_preview_images
		if $title->selected_subtitle;
	
	my $dir = $title->get_subtitle_preview_dir;
	my @files = glob ("$dir/*.pgm");
	
	foreach my $file ( @files ) {
		$self->show_preview_image (
			filename => $file
		);
	}

	1;	
}

sub show_preview_image {
	my $self = shift;
	my %par = @_;
	my $filename = @par{'filename'};

	my $subtitle = $self->selected_title->selected_subtitle;

	my $srtx_file = $filename;
	$srtx_file =~ s/\d+\.pgm//;
	$srtx_file .= ".srtx";

	my $fh = FileHandle->new;
	open ($fh, $srtx_file) or die "can't read $srtx_file";
	my $time;
	while (<$fh>) {
		if ( /^(\d+:\d+:\d+)/ ) {
			$time = $1;
		}
		last if /^$filename/;
	}
	close $fh;

	$subtitle->add_preview_image (
		filename => $filename,
		time     => $time,
	);

	my $hbox = $self->subtitle_widgets->{preview_images_hbox};

	my $frame = Gtk::Frame->new ($time);
	$frame->show;
	$frame->set_label_align(0.5, 1);
	$hbox->pack_start ($frame, 1, 0, 0);

	my $image = Video::DVDRip::GUI::ImageClip->new (
		filename   => $filename,
		gtk_window => $self->comp('main')->widget,
		thumbnail  => 1,
		no_clip    => 1,
	);
	
	$image->draw;

	my $vbox = Gtk::VBox->new;
	$vbox->show;
	$vbox->pack_start ($image->widget, 0, 1, 0);
	$vbox->set_border_width(5);

	$frame->add ($vbox);

	1;
}

sub subtitle_test_transcode {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	my $subtitle = $title->selected_subtitle;
	return 1 if not $subtitle;

	if ( not $subtitle->preview_images or
	     @{$subtitle->preview_images} == 0 ) {
		$self->message_window (
			message => "Please grab preview images first."
		);
		return 1;
	}
	
	$self->transcode ( subtitle_test => 1 );
	
	1,
}

sub subtitle_test_view {
	my $self = shift;
	my %par = @_;
	my ($title) = @par{'title'};

	$title ||= $self->selected_title;
	return 1 if not $title;

	$title->set_subtitle_test ( 1 );
	my $filename = $title->target_avi_file;
	$title->set_subtitle_test ( undef );
	
	$filename .= "*.mpg" if $filename !~ /\.[^.]+$/;
	
	my @files = glob ($filename);

	if ( @files == 0 or not -f $files[0] ) {
		$self->message_window (
			message => "You need to transcode the subtitles first."
		);
		return 1;
	}
	
	my $command = $title->get_view_avi_command (
		command_tmpl => $self->config('play_file_command'),
		file => $filename,
	);

	system ($command." &");
	1;
}

sub suggest_render_black_bars {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	$title->suggest_subtitle_on_black_bars;
	
	$self->make_previews;
	$self->show_preview_images;
	$self->init_adjust_values;
	$self->init_subtitle_specific_values;

	1;
}

sub suggest_render_full_size {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	$title->suggest_subtitle_on_movie;
	
	$self->make_previews;
	$self->show_preview_images;
	$self->init_adjust_values;
	$self->init_subtitle_specific_values;

	1;
}

sub create_vobsub_now {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $subtitle = $title->selected_subtitle;	
	return 1 if not $subtitle;

	if ( not -f $subtitle->ifo_file ) {
		$self->message_window (
			message =>
				"Need IFO files in place.\n".
				"You must re-read TOC from DVD."
		);
		return 1;
	}

	my $nr;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;
	my $job  = Video::DVDRip::Job::ExtractPS1->new (
		nr    => ++$nr,
		title => $title,
	);
	$job->set_subtitle ( $subtitle );
	
	$last_job = $exec->add_job ( job => $job );

	$job  = Video::DVDRip::Job::CreateVobsub->new (
		nr    => ++$nr,
		title => $title,
	);
	$job->set_subtitle ( $subtitle );
	$job->set_depends_on_jobs ( [ $last_job ] );

	$last_job = $exec->add_job ( job => $job );
	
	$exec->execute_jobs;

	1;
}

sub view_vobsub {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	my $subtitle = $title->selected_subtitle;	
	return 1 if not $subtitle;

	if ( not $self->has ( "mplayer" ) ) {
		$self->message_window (
			message => "You need Mplayer to view vobsub files."
		);
		return 1;
	}

	if ( $title->project->rip_mode ne 'rip' ) {
		$self->message_window (
			message => "This is only supported for ripped movies."
		);
		return 1;
	}

	if ( not $subtitle->vobsub_file_exists ) {
		$self->message_window (
			message => "What about creating the vobsub file first?"
		);
		return 1;
	}

	my $command = $title->get_view_vobsub_command (
		subtitle => $subtitle
	);
	
	system ("$command &");

	1;
}

sub create_splitted_vobsub {
	my $self = shift;
	my %par = @_;
	my ($exec, $last_job) = @par{'exec','last_job'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if not $title->has_vobsub_subtitles;
	
	my $files = $title->get_split_files;

	if ( @{$files} == 0 ) {
		$self->message_window (
			message =>
				"No splitted target files available.\n".
				"First transcode and split the movie."
		);
		
		return 1;
	}

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		if ( not -f $subtitle->ifo_file ) {
			$self->message_window (
				message =>
					"Need IFO files in place.\n".
					"You must re-read TOC from DVD."
			);
			return 1;
		}
	}

	my $nr;
	my $job;
	$exec ||= Video::DVDRip::GUI::ExecuteJobs->new;

	$job  = Video::DVDRip::Job::CountFramesInFile->new (
		nr    => ++$nr,
		title => $title,
	);
	
	$job->set_depends_on_jobs ( [$last_job] ) if $last_job;
	
	my $count_job = $last_job = $exec->add_job ( job => $job );

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		next if not $subtitle->tc_vobsub;

		$job  = Video::DVDRip::Job::ExtractPS1->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_subtitle ( $subtitle );

		$last_job = $exec->add_job ( job => $job );

		my $file_nr = 0;
		foreach my $file ( @{$files} ) {
			$job  = Video::DVDRip::Job::CreateVobsub->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$job->set_subtitle ( $subtitle );
			$job->set_count_job ( $count_job );
			$job->set_file_nr ( $file_nr );
	
			$last_job = $exec->add_job ( job => $job );

			++$file_nr;
		}
	}

	$exec->execute_jobs;

	1;
}

sub create_non_splitted_vobsub {
	my $self = shift;
	my %par = @_;
	my ($exec, $last_job) = @par{'exec','last_job'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if not $title->has_vobsub_subtitles;
	
	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		if ( not -f $subtitle->ifo_file ) {
			$self->message_window (
				message =>
					"Need IFO files in place.\n".
					"You must re-read TOC from DVD."
			);
			return 1;
		}
	}

	my $nr;
	my $job;
	$exec ||= Video::DVDRip::GUI::ExecuteJobs->new;

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		next if not $subtitle->tc_vobsub;

		$job  = Video::DVDRip::Job::ExtractPS1->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_subtitle ( $subtitle );

		$last_job = $exec->add_job ( job => $job );

		$job  = Video::DVDRip::Job::CreateVobsub->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$job->set_subtitle ( $subtitle );
	
		$last_job = $exec->add_job ( job => $job );
	}

	$exec->execute_jobs;

	1;
}

1;
