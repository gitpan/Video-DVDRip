# $Id: Depend.pm,v 1.2 2003/02/10 11:58:09 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Depend;

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

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " Dependency check");
	$win->border_width(0);
	$win->realize;
	$win->set_default_size ( 700, 420 );

	# Register component and window ------------------------------
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);
	$self->set_comp( 'depend' => $self );
	$win->signal_connect ("destroy", sub { $self->set_comp( 'depend' => "" ); } );

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
	
	$frame = Gtk::Frame->new ("Required tools");
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
		"Name",
		"Comment",
		"Mandatory",
		"Suggested",
		"Minimum",
		"Maximum",
		"Installed",
		"Ok",
	);
	$clist->set_column_width( 0, 80 );
	$clist->set_column_width( 1, 220 );
	$clist->set_column_width( 2, 60 );
	$clist->set_column_width( 3, 60 );
	$clist->set_column_width( 4, 50 );
	$clist->set_column_width( 5, 50 );
	$clist->set_column_width( 6, 50 );
	$clist->set_column_width( 7, 20 );
	$clist->show,
	$sw->add ($clist);
	$clist->set_selection_mode( 'browse' ); 

	$self->gtk_widgets->{depend_clist} = $clist;

	$label = Gtk::Label->new (
		"- Mandatory tools must be present with the minimum version listed.\n".
		"- Non mandatory tools may be missing or too old - features are disabled then.\n".
		"- Suggested numbers are the versions the author works with, so they are well tested."
	);
	$label->set_justify ("left");
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($label, 0, 1, 0);
	$vbox->pack_start ($hbox, 0, 1, 0);

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

	$self->init_depend_list;

	$win->show;

	return 1;
}

sub init_depend_list {
	my $self = shift;

	my $tools = $self->depend_object->tools;
	my ($clist, $rows);

	$clist = $self->gtk_widgets->{depend_clist};

	$clist->freeze;
	$clist->clear;

	my $highlighted = $clist->style->copy;
	$highlighted->fg('normal',$self->gdk_color('ff0000'));
	
	my $i = 0;
	foreach my $tool ( sort { $tools->{$a}->{order} <=> $tools->{$b}->{order} }
			   keys %{$tools} ) {
		my $def = $tools->{$tool};
		$clist->append (
			$tool,
			$def->{comment},
			($def->{optional} ? "No" : "Yes"),
			$def->{suggested},
			$def->{min},
			($def->{max} || "-"),
			$def->{installed},
			($def->{installed_ok} ? "Yes" : "No"),
		);
		$clist->set_row_style($i, $highlighted) if not $def->{installed_ok};
		++$i;
	}

	$clist->select_row ( 0, 0 );

	$clist->thaw;

	1;
}

1;
