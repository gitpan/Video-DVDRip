# $Id: ClipZoomTab.pm,v 1.9 2001/12/09 11:58:25 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

sub adjust_widgets		{ shift->{adjust_widgets}		}	# href
sub set_adjust_widgets		{ shift->{adjust_widgets}	= $_[1] }

#------------------------------------------------------------------------
# Build Adjustments Tab
#------------------------------------------------------------------------

sub create_adjust_tab {
	my $self = shift; $self->trace_in;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	my $selected_title = $self->create_selected_title;
	$vbox->pack_start ( $selected_title, 0, 1, 0);

	my ($label, $entry, $popup_menu, $popup, $item,
	    $box, $image, $button, $frame, $hbox);

	# preview images -------------------------------------------------

	my $title = $self->selected_title;

	$frame = Gtk::Frame->new ("Preview Images");
	$frame->show;
	$vbox->pack_start ( $frame, 0, 1, 0);

	$box = Gtk::VBox->new;
	$box->show;
	$frame->add ($box);
	
	# preview frame
	$hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;
	$box->pack_start($hbox, 0, 1, 0);

	$label = Gtk::Label->new ("Grab Preview Frame #");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	
	$entry = Gtk::Entry->new;
	$entry->set_usize(80, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);
	$self->adjust_widgets->{preview_frame_nr} = $entry;

	$button = Gtk::Button->new_with_label ("Grab Frame from ripped VOB");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->grab_preview_frame } );
	$hbox->pack_start($button, 0, 1, 0);

	# images

	$hbox = Gtk::HBox->new (0, 20);
	$hbox->set_border_width(5);
	$hbox->show;
	$box->pack_start($hbox, 0, 1, 0);

	# Clipping 1

	$box = Gtk::VBox->new;
	$box->show;
	$hbox->pack_start($box, 0, 1, 0);
	
	$frame = Gtk::Frame->new;
	$frame->show;
	$box->pack_start ($frame, 0, 1, 0);
	
	$image = Video::DVDRip::GUI::ImageClip->new (
		gtk_window => $self->comp('main')->widget,
		width      => 180,
		height     => 160,
		thumbnail  => $self->config('thumbnail_factor'),
		no_clip    => 1,
	);
	$frame->add ($image->widget);
	$image->widget->signal_connect (
		'button_press_event', sub {
			$self->open_preview_window (
				type => 'clip1'
			);
		}
	);

	$self->adjust_widgets->{image_clip1} = $image;

	$label = Gtk::Label->new ("After 1st Clipping");
	$label->show;
	$box->pack_start ($label, 0, 1, 0);
	$label = Gtk::Label->new ("");
	$label->show;
	$box->pack_start ($label, 0, 1, 0);
	$self->adjust_widgets->{clip1_info_label} = $label;

	# Zoom

	$box = Gtk::VBox->new;
	$box->show;
	$hbox->pack_start($box, 0, 1, 0);
	
	$frame = Gtk::Frame->new;
	$frame->show;
	$box->pack_start ($frame, 0, 1, 0);
	
	$image = Video::DVDRip::GUI::ImageClip->new (
		gtk_window => $self->comp('main')->widget,
		width      => 180,
		height     => 160,
		thumbnail  => $self->config('thumbnail_factor'),
		no_clip    => 1,
	);
	$frame->add ($image->widget);
	$image->widget->signal_connect (
		'button_press_event', sub {
			$self->open_preview_window (
				type => 'zoom'
			);
		}
	);

	$self->adjust_widgets->{image_zoom} = $image;
	
	$label = Gtk::Label->new ("After Zoom");
	$label->show;
	$box->pack_start ($label, 0, 1, 0);
	$label = Gtk::Label->new ("");
	$label->show;
	$box->pack_start ($label, 0, 1, 0);
	$self->adjust_widgets->{zoom_info_label} = $label;

	# Clipping 2

	$box = Gtk::VBox->new;
	$box->show;
	$hbox->pack_start($box, 0, 1, 0);
	
	$frame = Gtk::Frame->new;
	$frame->show;
	$box->pack_start ($frame, 0, 1, 0);
	
	$image = Video::DVDRip::GUI::ImageClip->new (
		gtk_window => $self->comp('main')->widget,
		width      => 180,
		height     => 160,
		thumbnail  => $self->config('thumbnail_factor'),
		no_clip    => 1,
	);
	$frame->add ($image->widget);
	$image->widget->signal_connect (
		'button_press_event', sub {
			$self->open_preview_window (
				type => 'clip2'
			);
		}
	);

	$self->adjust_widgets->{image_clip2} = $image;
	
	$label = Gtk::Label->new ("After 2nd Clipping");
	$label->show;
	$box->pack_start ($label, 0, 1, 0);
	$label = Gtk::Label->new ("");
	$label->show;
	$box->pack_start ($label, 0, 1, 0);
	$self->adjust_widgets->{clip2_info_label} = $label;

	# Adjust Size and Clipping Parameters ------------------------------

	$frame = Gtk::Frame->new ("Adjust Clip and Zoom Parameters");
	$frame->show;
	$vbox->pack_start ( $frame, 0, 1, 0);

	$hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	$frame->add ($hbox);

	my $table = Gtk::Table->new ( 5, 3, 0 );
	$table->show;
	$table->set_row_spacings ( 10 );
	$table->set_col_spacings ( 10 );
	$hbox->pack_start ($table, 0, 1, 0);

	# Presets Menu
	my $row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Presets");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;

	my $presets = $self->config_object->presets;
	my $i = 0;
	foreach my $preset ( @{$presets} ) {
		$item = Gtk::MenuItem->new ($preset->title);
		$item->show;
		$item->signal_connect ("select", sub {
			my ($widget, $name) = @_;
			my $title = $self->selected_title;
			return 1 if not $title;
			$title->set_preset ($name);
		}, $preset->name);
		$popup_menu->append($item);
		++$i;
	}

	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	
	$table->attach_defaults ($popup, 1, 2, $row, $row+1);

	$self->adjust_widgets->{preset_popup}      = $popup;
	$self->adjust_widgets->{preset_popup_menu} = $popup_menu;

	$button = Gtk::Button->new_with_label ("Apply Preset Values");
	$button->show;
	$button->signal_connect ("clicked", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		my $preset = $self->config_object->get_preset (
			name => $title->preset
		);
		return if not $preset;
		$title->apply_preset ( preset => $preset );
		$self->make_previews;
		$self->init_adjust_values;
	});
	$table->attach_defaults ($button, 2, 3, $row, $row+1);

	# Clipping #1
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("1st Clipping");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$label = Gtk::Label->new("Top");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip1_top}      = $entry;

	$label = Gtk::Label->new("Bottom");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip1_bottom}      = $entry;

	$label = Gtk::Label->new("Left");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip1_left}      = $entry;

	$label = Gtk::Label->new("Right");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip1_right}      = $entry;

	$button = Gtk::Button->new_with_label (" Generate Preview Images ");

	$button->show;
	$button->signal_connect ("clicked", sub {
		$self->make_previews;
		$self->show_preview_images;
	});
	$table->attach_defaults ($button, 2, 3, $row, $row+1);

	# Zoom
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Zoom");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach_defaults ($hbox, 1, 3, $row, $row+1);

	$label = Gtk::Label->new("Width");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_zoom_width}      = $entry;

	$label = Gtk::Label->new("Height");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_zoom_height}      = $entry;

	$label = Gtk::Label->new ("");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$self->adjust_widgets->{tc_zoom_info}        = $label;

	# fast resizing
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Use Fast Resizing");
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

	$self->adjust_widgets->{tc_fast_resize_yes} = $radio_yes;
	$self->adjust_widgets->{tc_fast_resize_no}  = $radio_no;

	# Clipping #2
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("2nd Clipping");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach_defaults ($hbox, 0, 1, $row, $row+1);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$label = Gtk::Label->new("Top");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip2_top}      = $entry;

	$label = Gtk::Label->new("Bottom");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip2_bottom}   = $entry;

	$label = Gtk::Label->new("Left");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip2_left}     = $entry;

	$label = Gtk::Label->new("Right");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->set_text ("");
	$entry->set_usize(40, undef);
	$entry->show;
	$hbox->pack_start($entry, 0, 1, 0);

	$self->adjust_widgets->{tc_clip2_right}      = $entry;

	$button = Gtk::Button->new_with_label (" Move 2nd Clipping to 1st ");

	$button->show;
	$button->signal_connect ("clicked", sub {
		$self->move_clip2_to_clip1;
	});
	$table->attach_defaults ($button, 2, 3, $row, $row+1);

	# connect changed signals
	my $widgets = $self->adjust_widgets;
	foreach my $attr (qw ( preview_frame_nr
			       tc_zoom_width tc_zoom_height
			       tc_clip1_top  tc_clip1_bottom
			       tc_clip1_left tc_clip1_right
       			       tc_clip2_top  tc_clip2_bottom
			       tc_clip2_left tc_clip2_right )) {
		$widgets->{$attr}->signal_connect ("changed", sub {
			my ($widget, $method) = @_;
			$self->selected_title->$method ( $widget->get_text );
			$self->update_fast_resize_info;
		}, "set_$attr");
	}

	$self->adjust_widgets->{tc_fast_resize_yes}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_fast_resize(1);
			$self->update_fast_resize_info;
		}
	);
	$self->adjust_widgets->{tc_fast_resize_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_fast_resize(0);
			$self->update_fast_resize_info;
		}
	);

	return $vbox;
}

sub init_adjust_values {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if not $self->adjust_widgets->{preview_frame_nr};

	$self->show_preview_images;

	my $widgets = $self->adjust_widgets;
	foreach my $attr (qw ( preview_frame_nr
			       tc_zoom_width tc_zoom_height
			       tc_clip1_top  tc_clip1_bottom
			       tc_clip1_left tc_clip1_right
       			       tc_clip2_top  tc_clip2_bottom
			       tc_clip2_left tc_clip2_right )) {
		$widgets->{$attr}->set_text ($self->selected_title->$attr());
	}

	my $preset_name = $title->preset;
	my $i = 0;
	foreach my $preset ( @{$self->config_object->presets} ) {
		last if $preset_name eq $preset->name;
		++$i;
	}
	$i = 0 if $i >= @{$self->config_object->presets};
	$widgets->{preset_popup}->set_history ($i);

	my $fast_resize = $title->tc_fast_resize;

	$widgets->{tc_fast_resize_yes}->set_active($fast_resize);
	$widgets->{tc_fast_resize_no}->set_active(!$fast_resize);

	$self->update_fast_resize_info;

	1;
}

sub update_fast_resize_info {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if not $self->adjust_widgets->{preview_frame_nr};

	my $info = "";
	if ( $title->tc_fast_resize ) {
		my ($width_n, $height_n, $err_div32, $err_shrink_expand) =
			$title->get_fast_resize_options;

		if ( $err_div32 or $err_shrink_expand ) {
			$info .= "32 boundary! " if $err_div32;
			$info .= "shrink-expand!" if $err_shrink_expand;
			$info =~ s! $!!;
			$info =~ s! s! / s!;
			$info = "Err: $info";
		} else {
			$info = "Fast Resize: Ok";
		}
	}

	$self->adjust_widgets->{tc_zoom_info}->set_text ($info);

	1;
}

sub show_preview_images {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};

	my $title = $self->selected_title;
	return 1 if not $title;
	
	my ($image, @types, $filename);

	if ( $type ) {
		push @types, $type;
	} else {
		@types = qw ( clip1 zoom clip2 );
	}

	my ($width, $height, $text, $ratio);
	foreach $type ( @types ) {
		$image = $self->adjust_widgets->{"image_$type"};
		next if not $image;

		$filename = $title->preview_filename (type => $type);
		if ( not -f $filename ) {
			$image->set_gdk_pixbuf(undef);
			next;
		}

		$image->load_image (
			filename => $filename
		);
		$image->draw;
	}

	$self->show_preview_labels ( type => $type );
	
	1;
}

sub show_preview_labels {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};

	my $title = $self->selected_title;
	return 1 if not $title;
	
	my ($image, @types, $filename);

	if ( $type ) {
		push @types, $type;
	} else {
		@types = qw ( clip1 zoom clip2 );
	}

	my ($width, $height, $warn_width, $warn_height, $text, $ratio);
	foreach $type ( @types ) {
		$image = $self->adjust_widgets->{"image_$type"};
		$width  = $image->image_width;
		$height = $image->image_height;
		next if $width == 0 or $height == 0;
		$ratio  = sprintf ("%2.2f", ($width/$height));
		$ratio  = "4:3" if $ratio eq '1.33';
		$ratio  = "16:9" if $ratio eq '1.77';
		$warn_width = ($width%8) ? "!":"";
		$warn_height = ($height%8) ? "!":"";
		$text = sprintf ("Size: %d%sx%d%s, Ratio: %s",
			$width, $warn_width, $height, $warn_height,
			$ratio
		);
		
		$self->adjust_widgets->{$type."_info_label"}->set_text($text);
	}

	$self->update_fast_resize_info;
	
	1;
}

sub grab_preview_frame {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;
	
	my $frame_nr = $title->preview_frame_nr;
	my $filename = $title->preview_filename( type => 'orig' );

	return 1 if not defined $frame_nr;

	if ( not $title->rip_time ) {
		$self->message_window (
			message => "You first have to rip this title."
		);
		return 1;
	}

	if ( $frame_nr > $title->frames or $frame_nr !~ /^\d+/ ) {
		$self->message_window (
			message => "Illegal frame number. Maximum is ".
				   ($title->frames-1)
		);
		return 1;
	}

	my $fh = $title->take_snapshot_async_start (
		frame    => $frame_nr,
		filename => $filename,
	);

	$self->comp('progress')->open_continious_progress (
		max_value => $frame_nr,
		label     => "Grabbing Preview Image",
		fh        => $fh,
		get_progress_callback => sub {
			my %par = @_;
			my ($buffer) = @par{'buffer'};
			$buffer =~ /\[0+-(\d+)\].*?$/;
			return $1;
		},
		finished_callback => sub {
			$title->take_snapshot_async_stop ( fh => $fh );
			$self->make_previews;
			$self->show_preview_images;
			return;
		},
		cancel_callback => sub {
			close $fh;
		},
	);
	
	1;
}

sub make_previews {
	my $self = shift; $self->trace_in;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	$title->make_preview_clip1;
	$title->make_preview_zoom;
	$title->make_preview_clip2;
	
	1;
}

sub open_preview_window {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	return 1 if defined $self->adjust_widgets->{"window_$type"};
	my $title = $self->selected_title;
	return 1 if not $title;

	my $file_type;
	$file_type = 'orig' if $type eq 'clip1';
	$file_type = 'zoom' if $type eq 'zoom';
	$file_type = 'zoom' if $type eq 'clip2';

	my $filename = $title->preview_filename (type => $file_type);
	return 1 if not -f $filename;

	my $win = Gtk::Window->new;
	$win->set_uposition (10,10);
	$win->signal_connect( 'destroy', sub {
		$self->adjust_widgets->{"window_$type"} = undef;
		$self->make_previews if $type ne 'zoom';
		$self->show_preview_images;
	} );
	$win->set_title ("Adjust $type");
	$win->show;
	
	my $vbox = Gtk::VBox->new;
	$vbox->show;
	$win->add($vbox);

	my $hbox = Gtk::HBox->new;
	$hbox->show;

	my $ic = Video::DVDRip::GUI::ImageClip->new (
		gtk_window => $win,
		filename   => $filename,
		changed_callback => sub {
			my %par = @_;
			my ($clip_type, $value) = @par{'type','value'};
			$clip_type =~ s/^clip/tc_$type/;
			my $old_value = $self->adjust_widgets
			     		     ->{$clip_type}
			     		     ->get_text;
			$self->adjust_widgets
			     ->{$clip_type}
			     ->set_text ($value);

			if ( $clip_type =~ /left/ or $clip_type =~ /right/ ) {
				my $width = $self->adjust_widgets->{"image_$type"}->image_width;
				$width -= $value-$old_value;
				$self->adjust_widgets->{"image_$type"}->set_image_width($width);
			} else {
				my $height = $self->adjust_widgets->{"image_$type"}->image_height;
				$height -= $value-$old_value;
				$self->adjust_widgets->{"image_$type"}->set_image_height($height);
			}
			$self->show_preview_labels ( type => $type );
		},
		no_clip => ($type eq 'zoom'),
	);

	if ( $type eq 'clip1' ) {
		$ic->set_clip_top    ($title->tc_clip1_top);
		$ic->set_clip_bottom ($title->tc_clip1_bottom);
		$ic->set_clip_left   ($title->tc_clip1_left);
		$ic->set_clip_right  ($title->tc_clip1_right);
	} elsif ( $type eq 'clip2' ) {
		$ic->set_clip_top    ($title->tc_clip2_top);
		$ic->set_clip_bottom ($title->tc_clip2_bottom);
		$ic->set_clip_left   ($title->tc_clip2_left);
		$ic->set_clip_right  ($title->tc_clip2_right);
	}

	$ic->calculate_knobs;

	$hbox->pack_start($ic->widget, 0, 1, 0);
	$vbox->pack_start($hbox, 0, 1, 0);

	$self->adjust_widgets->{"window_$type"} = $win;

	1;
}

sub move_clip2_to_clip1 {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	return 1 if $title->tc_fast_resize;

	my $clip1_top    = $title->tc_clip1_top;
	my $clip1_bottom = $title->tc_clip1_bottom;
	my $clip1_left   = $title->tc_clip1_left;
	my $clip1_right  = $title->tc_clip1_right;

	if ( $clip1_top or $clip1_bottom or $clip1_left or $clip1_right ) {
		$self->message_window (
			message => "2nd clipping parameters can only moved\n".
				   "to 1st clipping parameters, if 1st clipping\n".
				   "is not defined."
		);
		return 1;
	}
	
	my $width        = $title->width;
	my $height       = $title->height;
	
	my $zoom_width   = $title->tc_zoom_width;
	my $zoom_height  = $title->tc_zoom_height;
	
	my $x_factor = $zoom_width/$width;
	my $y_factor = $zoom_height/$height;
	
       	my $clip2_top    = $title->tc_clip2_top;
	my $clip2_bottom = $title->tc_clip2_bottom;
	my $clip2_left   = $title->tc_clip2_left;
	my $clip2_right  = $title->tc_clip2_right;

	my $clip1_top    = $clip2_top    / $y_factor;
	my $clip1_bottom = $clip2_bottom / $y_factor;
	my $clip1_left   = $clip2_left   / $x_factor;
	my $clip1_right  = $clip2_right  / $x_factor;
	
	$width  = $width  - $clip1_left - $clip1_right;
	$height = $height - $clip1_top  - $clip1_bottom;
	
	$zoom_width  = $width  * $x_factor;
	$zoom_height = $height * $y_factor;
	
	$title->set_tc_clip1_top    (int($clip1_top));
	$title->set_tc_clip1_bottom (int($clip1_bottom));
	$title->set_tc_clip1_left   (int($clip1_left));
	$title->set_tc_clip1_right  (int($clip1_right));
	$title->set_tc_zoom_width   (int($zoom_width));
	$title->set_tc_zoom_height  (int($zoom_height));
	$title->set_tc_clip2_top    (0);
	$title->set_tc_clip2_bottom (0);
	$title->set_tc_clip2_left   (0);
	$title->set_tc_clip2_right  (0);

	$self->make_previews;
	$self->init_adjust_values;

	1;
}

1;
