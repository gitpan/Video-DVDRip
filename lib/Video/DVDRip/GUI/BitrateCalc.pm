# $Id: BitrateCalc.pm,v 1.6 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::BitrateCalc;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

sub single_instance_window { 1 }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

# GUI Stuff ----------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	$self->set_gtk_widgets ({});

	my $title = $self->comp('project')->selected_title;

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name')." ".__"Storage and bitrate calculation details");
	$win->border_width(0);
	$win->realize;
	$win->set_default_size ( 580, 330 );

	# Register component and window ------------------------------
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);
	$self->set_comp( 'bitrate_calc' => $self );
	$win->signal_connect ("destroy", sub { $self->set_comp( 'bitrate_calc' => "" ); } );

	# Build dialog -----------------------------------------------
	my $dialog_vbox = Gtk::VBox->new;
	$dialog_vbox->show;
	$dialog_vbox->set_border_width(10);
	$win->add($dialog_vbox);

	my ($frame, $frame_hbox, $vbox, $hbox, $button, $clist, $sw, $item);
	my ($row, $table, $label, $popup_menu, $popup, %popup_entries, $entry);

	# Parameter Widgets ------------------------------------------
	
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->show;
	$dialog_vbox->pack_start($frame_hbox, 0, 1, 0);
	
	$frame = Gtk::Frame->new (__"Bitrate calculation details");
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
		__"Description",
		__"Operator",
		__"Value",
		__"Unit",
	);
	$clist->set_column_width( 0, 310 );
	$clist->set_column_width( 1, 60 );
	$clist->set_column_justification( 1, 'center' );
	$clist->set_column_width( 2, 60 );
	$clist->set_column_justification( 2, 'right' );
	$clist->set_column_width( 3, 50 );
	$clist->set_column_justification( 3, 'center' );
	$clist->show,
	$sw->add ($clist);
	$clist->set_selection_mode( 'browse' ); 

	$self->gtk_widgets->{calc_clist} = $clist;

	$hbox = Gtk::HBox->new (1, 10);
	$hbox->show;
	my $align = Gtk::Alignment->new ( 1, 0, 0, 1);
	$align->show;
	$align->add ($hbox);
	$vbox->pack_start ($align, 0, 1, 0);

	$button = Gtk::Button->new_with_label ("Ok");
	$button->set_usize (120,undef);
	$button->show;
	$button->signal_connect ("clicked", sub {
		$win->destroy;
	} );
	$hbox->pack_start ($button, 0, 0, 0);

	$self->init_calc_list;

	$win->show;

	return 1;
}

sub init_calc_list {
	my $self = shift;
	
	my $title = $self->comp('project')->selected_title;
	return if not $title;
	
	my $bc = Video::DVDRip::BitrateCalc->new (
		title      => $title,
		with_sheet => 1,
	);
	$bc->calculate_video_bitrate;
	my $sheet = $bc->sheet;
	
	my ($clist, $rows);

	$clist = $self->gtk_widgets->{calc_clist};

	$clist->freeze;
	$clist->clear;

	my $font = Gtk::Gdk::Font->load (
		"-*-helvetica-bold-r-*-*-*-120-*-*-*-*-*-*"
	);

	my $highlighted = $clist->style->copy;
	$highlighted->font($font);
	
	my $i = 0;
	foreach my $sheet_line ( @{$sheet} ) {
		$clist->append (
			$sheet_line->{label},
			$sheet_line->{operator},
			sprintf("%.2f",$sheet_line->{value}),
			$sheet_line->{unit},
		);
		if ( $sheet_line->{operator} =~ /^[=~]$/ ) {
			$clist->set_row_style($i, $highlighted);
		}
		++$i;
	}

	$clist->select_row ( 0, 0 );

	$clist->thaw;

	1;
}

1;
