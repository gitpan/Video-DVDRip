# $Id: VisualFrameRange.pm,v 1.3 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::VisualFrameRange;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

sub single_instance_window { 1 }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

sub build {
	my $self = shift; $self->trace_in;

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name')." ".__"Select a frame range");
	$win->border_width(0);
	$win->realize;
#	$win->set_default_size ( 600, undef );

	# Register component and window ------------------------------
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);
	$self->set_comp( 'visual_frame_range' => $self );
	$win->signal_connect ("destroy", sub { $self->set_comp( 'visual_frame_range' => "" ); } );

	# Build dialog -----------------------------------------------
	my $dialog_vbox = Gtk::VBox->new;
	$dialog_vbox->show;
	$dialog_vbox->set_border_width(10);
	$win->add($dialog_vbox);

	my ($frame, $frame_hbox, $vbox, $hbox, $button, $clist, $sw, $item);
	my ($row, $table, $label, $popup_menu, $popup, %popup_entries, $entry);

	# Parameter Widgets ------------------------------------------
	
	$frame = Gtk::Frame->new (__"Select a frame range");
	$frame->show;
	$dialog_vbox->pack_start ( $frame, 0, 1, 0);
	
	$vbox = Gtk::VBox->new;
	$vbox->show;
	$frame->add ($vbox);
	
	my $adj = Gtk::Adjustment->new ( 0.0, 0.0, 100.0, 1.0, 1.0, 0.0 );
	my $scale = new Gtk::HScale( $adj );
	$scale->set_update_policy( 'continuous' );
	$scale->show();
	$scale->set_draw_value( 0 );

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->set_border_width ( 5 );
	$hbox->pack_start( $scale, 1, 1, 0 );

	$vbox->pack_start ($hbox, 0, 1, 0);
	
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->set_border_width ( 5 );
	$vbox->pack_start ($hbox, 0, 1, 0);

	$label = Gtk::Label->new (__"Start frame");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_sensitive(0);
	$entry->set_usize (50, undef);
	$hbox->pack_start ($entry, 0, 1, 0);
	
	$label = Gtk::Label->new (__"End frame");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_sensitive(0);
	$entry->set_usize (50, undef);
	$hbox->pack_start ($entry, 0, 1, 0);
	
	$button = Gtk::Button->new (__"Set start");
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new (__"Set end");
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	
	$button = Gtk::Button->new (__"Close window");
	$button->show;
	$hbox->pack_start ($button, 0, 1, 0);
	
	$win->show;

	return 1;
}

1;
