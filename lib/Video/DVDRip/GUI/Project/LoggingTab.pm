# $Id: LoggingTab.pm,v 1.2 2002/01/03 17:40:01 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Video::DVDRip::GUI::Logger;

use Carp;
use strict;

#------------------------------------------------------------------------
# Build Logging Tab
#------------------------------------------------------------------------

sub create_logging_tab {
	my $self = shift; $self->trace_in;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	my $frame = Gtk::Frame->new ("Log Messages");
	$frame->show;

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	my $text_table = new Gtk::Table( 2, 2, 0 );
	$text_table->set_row_spacing( 0, 2 );
	$text_table->set_col_spacing( 0, 2 );
	$text_table->show();

	$hbox->pack_start($text_table, 1, 1, 0);

	my $text = new Gtk::Text( undef, undef );
	$text->show;
	$text->set_usize (undef, $self->config('main_window_height') - 200);
	$text->set_editable( 0 );
	$text->set_word_wrap ( 1 );
	$text_table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );

	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$text_table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );
	$vscrollbar->show();

	$frame->add ($hbox);
	$vbox->pack_start ( $frame, 0, 1, 0);

	my $logger = Video::DVDRip::GUI::Logger->new (
		text_widget => $text,
		project     => $self->project,
	);

	$self->set_logger ( $logger );

	return $vbox;
}

1;
