# $Id: ZoomCalculator.pm,v 1.8 2002/11/01 16:12:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::ZoomCalculator;

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

sub multi_instance_window { 1 }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

sub calc_results		{ shift->{calc_results}			}
sub set_calc_results		{ shift->{calc_results}		= $_[1] }

sub in_init			{ shift->{in_init}			}
sub set_in_init			{ shift->{in_init}		= $_[1]	}

sub fast_resize_align		{ shift->{fast_resize_align}		}
sub set_fast_resize_align	{ shift->{fast_resize_align}	= $_[1]	}

sub auto_clip			{ shift->{auto_clip}			}
sub set_auto_clip		{ shift->{auto_clip}		= $_[1]	}

sub achieve_result_align	{ shift->{achieve_result_align}		}
sub set_achieve_result_align	{ shift->{achieve_result_align}	= $_[1]	}

sub result_frame_align		{ shift->{result_frame_align}		}
sub set_result_frame_align	{ shift->{result_frame_align}	= $_[1]	}

sub target_size			{ shift->{target_size}			}
sub disc_size			{ shift->{disc_size}			}
sub disc_cnt			{ shift->{disc_cnt}			}
sub video_bitrate		{ shift->{video_bitrate}		}

sub set_target_size		{ shift->{target_size}		= $_[1]	}
sub set_disc_size		{ shift->{disc_size}		= $_[1]	}
sub set_disc_cnt		{ shift->{disc_cnt}		= $_[1]	}
sub set_video_bitrate		{ shift->{video_bitrate}	= $_[1]	}

# GUI Stuff ----------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	$self->set_gtk_widgets ({});

	my $title = $self->comp('project')->selected_title;

	$self->set_fast_resize_align(8);
	$self->set_auto_clip('clip2');
	$self->set_result_frame_align(16);
	$self->set_achieve_result_align('clip2');
	$self->set_disc_cnt ($title->tc_disc_cnt);
	$self->set_disc_size ($title->tc_disc_size);
	$self->set_target_size ($title->tc_target_size);
	$self->set_video_bitrate ($title->tc_video_bitrate);

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " Zoom Calculator");
	$win->border_width(0);
	$win->realize;
	$win->set_default_size ( 620, 540 );

	# Register component and window ------------------------------
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);

	# Build dialog -----------------------------------------------
	my $dialog_vbox = Gtk::VBox->new;
	$dialog_vbox->show;
	$dialog_vbox->set_border_width(10);
	$win->add($dialog_vbox);

	my ($frame, $frame_hbox, $vbox, $hbox, $button, $clist, $sw, $item);
	my ($row, $table, $label, $popup_menu, $popup, %popup_entries, $entry);
	my ($par_frames_hbox);

	# Parameter Widgets ------------------------------------------
	
	$par_frames_hbox = Gtk::HBox->new;
	$par_frames_hbox->show;
	$dialog_vbox->pack_start($par_frames_hbox, 0, 1, 0);
	
	# Left Parameter Frame -----------------------
	
	$frame = Gtk::Frame->new ("Parameters");
	$frame->show;
	$par_frames_hbox->pack_start($frame, 0, 1, 0);
	
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

	# Fast Resize Alignment
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Fast resize alignment");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		0  => "No Fast Resizing",
		8  => 8,
		16 => 16,
		32 => 32,
	);
	foreach my $key ( sort {$a <=> $b} keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if $self->in_init;
				$self->set_fast_resize_align($key)
			}, $key
		);
	}
	
	$popup->set_history(1);
	
	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->gtk_widgets->{fast_resize_align_popup} = $popup;

	# Result Frame Alignment
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Result frame align");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;

	$entry = Video::DVDRip::CheckedCombo->new (
		is_number	=> 1,
		is_min		=> 1,
	);

	$entry->show;
	$entry->set_popdown_strings (16);
	$entry->set_usize(150,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->gtk_widgets->{result_frame_align_entry} = $entry->entry;

	$entry->entry->signal_connect (
		"focus_out_event", sub {
			my $val = int($_[0]->get_text / 2 + 0.5)*2;
			$self->set_result_frame_align($val);
			$_[0]->set_text($val);
		}
	);

	# Achieve Result Frame Align With
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Achieve result align");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		"clip2" => "Using clip2",
		"zoom"  => "Using zoom",
	);
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if $self->in_init;
				$self->set_achieve_result_align($key)
			}, $key
		);
	}
	
	$popup->set_history(0);
	
	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->gtk_widgets->{achieve_result_align_popup} = $popup;

	# Auto Clipping
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Auto clipping");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		"clip1" => "Yes - use clip1",
		"clip2" => "Yes - use clip2",
		"no"	=> "No - take existent clip1",
	);
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if $self->in_init;
				$self->set_auto_clip($key)
			}, $key
		);
	}
	
	$popup->set_history(1);
	
	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$self->gtk_widgets->{auto_clip_popup} = $popup;

	# Right Parameter Frame -----------------------

	$frame = $self->create_video_bitrate_calc;
	$par_frames_hbox->pack_start($frame, 1, 1, 0);

	# Results ----------------------------------------------------

	$frame = Gtk::Frame->new ("Zoom Calculations");
	$frame->show;
	$dialog_vbox->pack_start($frame, 1, 1, 0);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);
	$sw = new Gtk::ScrolledWindow( undef, undef );
	$vbox->pack_start ($sw, 1, 1, 0);
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	$clist = Gtk::CList->new_with_titles (
		"Result size    ",
		"BPP     ",
		"Eff. AR    ",
		"AR error    ",
		"Clip1 (t/b/l/r)      ",
		"Zoom size    ",
		"Clip2 (t/b/l/r)      ",
	);
	$clist->show,
	$sw->add ($clist);
	$clist->set_selection_mode( 'browse' ); 

	$self->gtk_widgets->{calc_clist} = $clist;

	$hbox = Gtk::HBox->new (1, 10);
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);
	
	$button = Gtk::Button->new_with_label (" Cancel ");
	$button->show;
	$button->signal_connect ("clicked", sub { $win->destroy } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Refresh ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->init_calc_list } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Apply ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->apply_values } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Ok ");
	$button->show;
	$button->signal_connect ("clicked", sub {
		$self->apply_values;
		$win->destroy;
	} );
	$hbox->pack_start ($button, 0, 1, 0);

	$self->init_calc_list;

	$win->show;

	return 1;
}

sub create_video_bitrate_calc {
	my $self = shift;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $i);

	my $title = $self->comp('project')->selected_title;

	# Frame
	$frame = Gtk::Frame->new ("Video bitrate calculation");
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
	$label = Gtk::Label->new ("Target media");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

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

	$i = 0;
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"select", sub {
				$self->set_disc_cnt($key);
				$self->set_target_size(
					$key * $self->disc_size,
				);
				$self->gtk_widgets
				     ->{target_size}
				     ->set_text ($self->target_size);
				my $bitrate = $title->get_optimal_video_bitrate (
					target_size => $self->target_size
				);
				$self->gtk_widgets
				     ->{video_bitrate}
				     ->set_text ($bitrate);
				$self->set_video_bitrate($bitrate);
				1;
			}, $key
		);
		$popup->set_history($i) if $key == $self->disc_cnt;
		++$i;
	}
	$hbox->pack_start($popup, 1, 1, 0);
	
	$self->gtk_widgets->{disc_cnt_popup} = $popup;

	$label = Gtk::Label->new ("x");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Video::DVDRip::CheckedCombo->new (
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_popdown_strings (650, 700, 760);
	$entry->set_usize(60,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$entry->entry->signal_connect ("changed", sub {
		$self->set_disc_size ($_[0]->get_text);
		$self->set_target_size(
			$self->disc_cnt * $self->disc_size,
		);
		return 1 if not $self->gtk_widgets->{target_size};
		$self->gtk_widgets
		     ->{target_size}
		     ->set_text ($self->target_size);
		my $bitrate = $title->get_optimal_video_bitrate (
			target_size => $self->target_size
		);
		$self->gtk_widgets
		     ->{video_bitrate}
		     ->set_text ($bitrate);
		$self->set_video_bitrate($bitrate);
		1;
	});

	$entry->entry->set_text ($title->tc_disc_size);

	$self->gtk_widgets->{tc_disc_size_combo} = $entry;

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	# Target Size
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target size");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("MB");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->gtk_widgets->{target_size} = $entry;

	$entry->set_text($self->target_size);

	# Video Bitrate
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Video bitrate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("kbit/s");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$self->gtk_widgets->{video_bitrate} = $entry;

	$entry->set_text($self->video_bitrate);
	
	$entry->signal_connect ("changed", sub {
		$self->set_video_bitrate($_[0]->get_text);
		1;
	});

	return $frame;
}

sub init_calc_list {
	my $self = shift;
	
	my ($clist, $rows);

	$clist = $self->gtk_widgets->{calc_clist};

	$clist->thaw;
	$clist->clear;

	my $font = Gtk::Gdk::Font->load (
		"-*-helvetica-bold-r-*-*-*-120-*-*-*-*-*-*"
	);
	my $highlighted = $clist->style->copy;
	$highlighted->font($font);
	
	my $perfect = $clist->style->copy;
	$perfect->font($font);
	$perfect->fg('normal',$self->gdk_color('ff0000'));
	$perfect->fg('selected',$self->gdk_color('ff9999'));

	$font = Gtk::Gdk::Font->load (
		"-*-helvetica-medium-r-*-*-*-120-*-*-*-*-*-*"
	);
	my $normal = $clist->style->copy;
	$normal->font($font);

	my $fast_resize_align  = $self->fast_resize_align;
	my $result_align       = $self->result_frame_align;
	my $result_align_clip2 = ($self->achieve_result_align eq 'clip2');
	my $auto_clip          = ($self->auto_clip ne 'no');
	my $use_clip1	       = ($self->auto_clip eq 'clip1');
	my $video_bitrate      = $self->video_bitrate;

	$self->print_debug("
		fast_resize_align  => $fast_resize_align,
		result_align       => $result_align,
		result_align_clip2 => $result_align_clip2,
		auto_clip          => $auto_clip,
		use_clip1	   => $use_clip1,
		video_bitrate	   => $video_bitrate,
	");

	my $calc_lref = $self->comp('project')->selected_title->calculator (
		fast_resize_align  => $fast_resize_align,
		result_align       => $result_align,
		result_align_clip2 => $result_align_clip2,
		auto_clip          => $auto_clip,
		use_clip1	   => $use_clip1,
		video_bitrate	   => $video_bitrate,
	);	
	
	my $i = 0;
	foreach my $result ( @{$calc_lref} ) {
		$clist->append (
			"$result->{clip2_width}x$result->{clip2_height}",
			sprintf("%.3f", $result->{bpp}),
			sprintf("%.4f", $result->{eff_ar}),
			sprintf("%.4f%%", $result->{ar_err}),
			"$result->{clip1_top} / $result->{clip1_bottom} / ".
			"$result->{clip1_left} / $result->{clip1_right}",
			"$result->{zoom_width}x$result->{zoom_height}",
			"$result->{clip2_top} / $result->{clip2_bottom} / ".
			"$result->{clip2_left} / $result->{clip2_right}",
		);
		if ( $result->{ar_err} < 0.000001 ) {
			$clist->set_row_style($i, $perfect);
		} else {
			$clist->set_row_style(
				$i,
				$result->{ar_err} < 0.3 ? $highlighted:$normal
			);
		}
		++$i;
	}

	$clist->select_row ( 0, 0 );

	$self->set_calc_results ($calc_lref);

	1;
}

sub apply_values {
	my $self = shift;

	my ($row) = $self->gtk_widgets->{calc_clist}->selection;

	my $result  = $self->calc_results->[$row];
	my $project = $self->comp('project');
	my $title   = $project->selected_title;

	$title->set_tc_zoom_width    ( $result->{zoom_width}   );
	$title->set_tc_zoom_height   ( $result->{zoom_height}  );
	$title->set_tc_clip1_left    ( $result->{clip1_left}   );
	$title->set_tc_clip1_right   ( $result->{clip1_right}  );
	$title->set_tc_clip1_top     ( $result->{clip1_top}    );
	$title->set_tc_clip1_bottom  ( $result->{clip1_bottom} );
	$title->set_tc_clip2_left    ( $result->{clip2_left}   );
	$title->set_tc_clip2_right   ( $result->{clip2_right}  );
	$title->set_tc_clip2_top     ( $result->{clip2_top}    );
	$title->set_tc_clip2_bottom  ( $result->{clip2_bottom} );

	$title->set_tc_fast_resize   ( $self->fast_resize_align != 0 );
	$title->set_tc_disc_cnt      ( $self->disc_cnt );
	$title->set_tc_disc_size     ( $self->disc_size );
	$title->set_tc_target_size   ( $self->target_size );
	$title->set_tc_video_bitrate ( $self->video_bitrate );

	$project->make_previews;
	$project->init_adjust_values;
	$project->init_transcode_values;
	
	1;
}

1;
