# $Id: Filters.pm,v 1.9 2003/02/10 13:34:36 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Filters;

use base Video::DVDRip::GUI::Window;

use Video::DVDRip::GUI::Preview;

use strict;
use Carp;

my $TABLE_SPACING = 5;

sub single_instance_window { 1 }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

sub preview			{ shift->{preview}			}
sub in_filter_init		{ shift->{in_filter_init}		}
sub current_available_row	{ shift->{current_available_row}	}
sub current_selected_row	{ shift->{current_selected_row}		}
sub stop_in_progress		{ shift->{stop_in_progress}		}
sub pause_in_progress		{ shift->{pause_in_progress}		}
sub playing			{ shift->{playing}			}

sub set_preview			{ shift->{preview}		= $_[1]	}
sub set_in_filter_init		{ shift->{in_filter_init}	= $_[1]	}
sub set_current_available_row	{ shift->{current_available_row}= $_[1]	}
sub set_current_selected_row	{ shift->{current_selected_row}	= $_[1]	}
sub set_stop_in_progress	{ shift->{stop_in_progress}	= $_[1]	}
sub set_pause_in_progress	{ shift->{pause_in_progress}	= $_[1]	}
sub set_playing			{ shift->{playing}		= $_[1]	}

# GUI Stuff ----------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	$self->set_gtk_widgets ({});

	my $title = $self->comp('project')->selected_title;

	# register filter object accessor ----------------------------
	my $project = $self->comp('project');

	Video::DVDRip::GUI::Setting->add_object_accessor (
		name    => "title",
		access  => sub { $project->selected_title },
	);

	Video::DVDRip::GUI::Setting->add_object_accessor (
		name    => "filter_options",
		part_of => "title",
		access  => sub { $project->selected_title
				 ->tc_selected_filter_setting },
		set_method   => "set_value",
		get_method   => "get_value",
		passed_as    => "hash",
		value_option => "value",
	);

	Video::DVDRip::GUI::Setting->add_object_accessor (
		name    => "filter_setting",
		part_of => "title",
		access  => sub { $project->selected_title
				  ->tc_selected_filter_setting },
	);

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " Configure filters");
	$win->border_width(0);
	$win->realize;
	$win->set_default_size ( undef, 550 );

	# Register component and window ------------------------------
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);
	$self->set_comp( 'filters' => $self );
	$win->signal_connect ("destroy", sub { $self->destroy } );

	# Build dialog -----------------------------------------------
	my $dialog_vbox = Gtk::VBox->new;
	$dialog_vbox->show;
	$dialog_vbox->set_border_width(10);
	$win->add($dialog_vbox);

	my $toolbar           = $self->build_toolbar;
	my $filter_options    = $self->build_filter_options;
	my $filter_lists      = $self->build_filter_lists;

	my $table = Gtk::Table->new ( 1, 3, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$dialog_vbox->pack_start ($table, 1, 1, 0);


	$table->attach          ($filter_lists, 	0, 1, 0, 1,
				['fill','expand'],'shrink',0,0);
	$table->attach_defaults ($filter_options, 	0, 1, 1, 2);
	$table->attach		($toolbar, 		0, 1, 2, 3,
				['fill','expand'],'shrink',0,0);

	$self->init_available_filters_list;
	$self->init_selected_filters_list;

	Video::DVDRip::GUI::Setting->update_object_settings (
		name => "title",
	);

	$win->show;

	my $preview = Video::DVDRip::GUI::Preview->new (
		closed_cb    => sub {
			$self->preview_stop
		},
		selection_cb => sub { $self->preview_selection ( @_ ) },
		eof_cb => sub {
			$self->preview_stop ( reset_gui_only => 1 );
			Gtk->timeout_add (1000, sub {
				$self->preview_play;
				return 0;
			});
		},
	);
	$self->set_preview($preview);

	return 1;
}

sub destroy {
	my $self = shift;

	if ( $self->playing ) {
		$self->preview_stop;
	}

	$self->set_comp( 'filters' => "" );

	Video::DVDRip::GUI::Setting->remove_object_accessor (
		name => "filter_setting",
	);

	Video::DVDRip::GUI::Setting->remove_object_accessor (
		name => "filter_options",
	);

	Video::DVDRip::GUI::Setting->remove_object_accessor (
		name => "title",
	);

	1;
}

sub build_filter_lists {
	my $self = shift;
	
	my $available_filters = $self->build_available_filters;
	my $selected_filters  = $self->build_selected_filters;

	my $table = Gtk::Table->new ( 1, 2, 1 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );

	$table->attach          ($available_filters, 	0, 1, 0, 1,
				['fill','expand'],'shrink',0,0);
	$table->attach          ($selected_filters, 	1, 2, 0, 1,
				['fill','expand'],'shrink',0,0);

	return $table;
}

sub build_available_filters {
	my $self = shift;
	
	my $widgets = $self->gtk_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new ("Available filters");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	my $list_vbox = Gtk::VBox->new;
	$list_vbox->show;
	$frame_hbox->pack_start ( $list_vbox, 1, 1, 0);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	my $clist = Gtk::CList->new_with_titles (
		 "Name", "Description"
	);
	$clist->set_usize ( undef, 160 );
 	$clist->set_column_width( 0, 80 );
 	$clist->set_column_width( 1, 100 );
 	$clist->column_titles_passive;
 	$clist->show,
	$clist->set_selection_mode( 'single' ); 
	$clist->signal_connect ("select_row",   sub {
		return 1 if $self->in_filter_init;
		$self->select_available_filter (@_);
	} );
	$clist->signal_connect ("unselect_row", sub {
		return 1 if $self->in_filter_init;
		$self->unselect_available_filter (@_);
	} );

	$sw->add( $clist );

	$list_vbox->pack_start ($sw, 1, 1, 0);

	$widgets->{available_filters_clist} = $clist;
	
	$label = Gtk::Label->new (
		"Double click to add a filter.\n",
	);
#	$label->set_justify('left');
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($label, 1, 1, 0);

	$list_vbox->pack_start ($hbox, 1, 1, 0);
	
	return $frame;
}

sub build_selected_filters {
	my $self = shift;
	
	my $widgets = $self->gtk_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new ("Selected filters");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	my $list_vbox = Gtk::VBox->new;
	$list_vbox->show;
	$frame_hbox->pack_start ( $list_vbox, 1, 1, 0);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	my $clist = Gtk::CList->new_with_titles (
		 "Name", "Description", "id"
	);
	$clist->set_usize ( undef, 160 );
 	$clist->set_column_width( 0, 80 );
 	$clist->set_column_width( 1, 100 );
	$clist->set_column_visibility ( 2, 0 );
 	$clist->column_titles_passive;
	$clist->show,
	$clist->set_selection_mode( 'single' ); 
	$clist->signal_connect ("select_row",   sub {
		return 1 if $self->in_filter_init;
		$self->select_selected_filter (@_);
	} );
	$clist->signal_connect ("unselect_row", sub {
		return 1 if $self->in_filter_init;
		$self->unselect_selected_filter (@_);
	} );
	$clist->set_reorderable(1);
	$clist->signal_connect ('row-move', sub {
		$self->reorder_selected_filter ( @_ ) }
	);

	$sw->add( $clist );

	$list_vbox->pack_start ($sw, 1, 1, 0);
	
	$widgets->{selected_filters_clist} = $clist;

	$label = Gtk::Label->new (
		"Double click to remove a filter.\n".
		"Change order using drag 'n drop.",
	);
	$label->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($label, 1, 1, 0);

	$list_vbox->pack_start ($hbox, 1, 1, 0);
	
	return $frame;
}

sub build_filter_options {
	my $self = shift;
	
	my $widgets = $self->gtk_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button, $sep);

	# Frame
	$frame = Gtk::Frame->new ("Filter Options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# info area

	my $info_vbox = Gtk::VBox->new;
	$info_vbox->show;
	$info_vbox->set_border_width(5);
	$info_vbox->set_usize( 255, undef );

 	# sw is mainly for layout reasons (it's always inactive).
	# This way "Filter information" and Options look equal.

	my $sw = Gtk::ScrolledWindow->new;
	$sw->set_usize( 260, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );
	$sw->add_with_viewport ( $info_vbox );
 	$frame_hbox->pack_start ($sw, 0, 1, 0);
 
 	$hbox = Gtk::HBox->new;
	$hbox->show;
	$info_vbox->pack_start ($hbox, 0, 1, 0);
	
	$label = Gtk::Label->new ("Information");
	$label->show;
	$hbox->pack_start ($label , 0, 1, 0);

	$sep = Gtk::HSeparator->new;
	$sep->show;
	$info_vbox->pack_start ($sep, 0, 1, 0);

 	$hbox = Gtk::HBox->new;
	$hbox->show;
	$info_vbox->pack_start ($hbox, 0, 1, 0);

	$label = Gtk::Label->new ("");
	$label->show;
	$label->set_justify("left");
	$hbox->pack_start ($label , 0, 1, 0);

	$widgets->{filter_info_widget} = $label;
	$widgets->{filter_info_vbox}  = $hbox;

	# widget area

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	$frame_hbox->pack_start ( $sw, 1, 1, 0);

	my $vbox = Gtk::VBox->new (0, 2);
	$vbox->show;
	$vbox->set_border_width ( 5 );
	$sw->add_with_viewport( $vbox );

	$widgets->{filter_options_sw}   = $sw;

	return $frame;
}

sub build_toolbar {
	my $self = shift;
	
	my $widgets = $self->gtk_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $sep);
	my ($popup_menu, $popup, $item, %popup_entries, $button, $combo, $tip);

	my $top_hbox = Gtk::HBox->new;
	$top_hbox->show;

	# Frame
	$frame = Gtk::Frame->new ("Preview settings");
	$frame->show;
	$top_hbox->pack_start ($frame, 0, 1, 0);

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	Video::DVDRip::GUI::Setting::Text->new (
		object		=> "title",
		name		=> "tc_preview_buffer_frames",
		attr		=> "tc_preview_buffer_frames",
		tooltip		=> "Preview buffer frames",
		presets		=> [20, 50, 100, 150, 200],
		box		=> $frame_hbox,
	);

	Video::DVDRip::GUI::Setting::Text->new (
		object		=> "title",
		name		=> "tc_preview_start_frame",
		attr		=> "tc_preview_start_frame",
		tooltip		=> "Start frame number",
		box		=> $frame_hbox,
		is_number	=> 1,
		may_empty	=> 1,
		cond		=> sub {
			my $start = Video::DVDRip::GUI::Setting
					->by_name("tc_preview_start_frame")
					->widget->get_text;
			my $end   = Video::DVDRip::GUI::Setting
					->by_name("tc_preview_end_frame")
					->widget->get_text;
			return 1 if $start eq '' or $end eq '';
			return $start < $end;
		},
	);
	
	$label = Gtk::Label->new(" - ");
	$label->show;
	$frame_hbox->pack_start ($label, 0, 1, 0);

	Video::DVDRip::GUI::Setting::Text->new (
		object		=> "title",
		name		=> "tc_preview_end_frame",
		attr		=> "tc_preview_end_frame",
		tooltip		=> "End frame number",
		box		=> $frame_hbox,
		is_number	=> 1,
		may_empty	=> 1,
		cond		=> sub {
			my $start = Video::DVDRip::GUI::Setting
					->by_name("tc_preview_start_frame")
					->widget->get_text;
			my $end   = Video::DVDRip::GUI::Setting
					->by_name("tc_preview_end_frame")
					->widget->get_text;
			return 1 if $start eq '' or $end eq '';
			return $start < $end;
		},
	);

if ( 0 ) {
	$button = Gtk::Button->new ("...");
	$button->set_usize (20, undef);
	$button->show;
	$button->signal_connect ("clicked", sub {
		$self->comp('project')->open_visual_frame_range (
		);
	});
	$tip = Gtk::Tooltips->new;
	$tip->set_tip ($button, "Visually select frame range", undef);
	$frame_hbox->pack_start ($button, 0, 1, 0);
}
	# Frame
	$frame = Gtk::Frame->new ("Preview control");
	$frame->show;
	$top_hbox->pack_start ($frame, 0, 1, 0);

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	my $button_box = $frame_hbox;

	my @buttons = (
	   play  	=> ">:Open preview window and play:1",
	   apply	=> "A:Apply filter chain:0",
	   slower 	=> "-:Decrease preview speed:0",
	   faster 	=> "+:Increase preview speed:0",
	   pause 	=> "||:Pause/Resume:0",
	   undo		=> "U:Undo - view previous buffer:0",
	   slow_rewind	=> "<<:Step backward one frame:0",
	   slow_forward	=> ">>:Step forward one frame:0",
	   fast_rewind 	=> "<<<:Step backward several frames:0",
	   fast_forward	=> ">>>:Step forward several frames:0",
	   stop  	=> "O:Stop playing and close preview window:0", 
	);

	while ( @buttons ) {
		my $name = shift @buttons;
		my $desc = shift @buttons;
		my ($text, $tooltip, $sensitive) = split (":", $desc);
		if ( $name eq 'play' or $name eq 'pause' or $name eq 'undo' ) {
			$button = Gtk::ToggleButton->new ($text);
		} else {
			$button = Gtk::Button->new ($text);
		}
		$button->show;
		$button->set_usize ( 40, undef );
		$button_box->pack_start ( $button, 0, 1, 0 );
		$button->signal_connect ( "clicked", sub {
			my $method = "preview_$name";
			$self->$method();
		});
		$button->set_sensitive($sensitive);
		$widgets->{"preview_${name}_button"} = $button;
		my $tip = Gtk::Tooltips->new;
		$tip->set_tip ($button, $tooltip, undef);
	}

	return $top_hbox;
}

sub init_available_filters_list {
	my $self = shift;

	my $title = $self->comp('project')->selected_title;
	my $clist = $self->gtk_widgets->{"available_filters_clist"};

	my $filters = Video::DVDRip::FilterList->get_filter_list->filters;
	my $tc_filter_settings = $title->tc_filter_settings;

	$clist->freeze;
	$clist->clear;

	my $filter;
	foreach my $filter_name ( sort keys %{$filters} ) {
		$filter = $filters->{$filter_name};
		next if not $filter->can_multiple and
			$tc_filter_settings->filter_used (
				filter_name => $filter_name
			);
		$clist->append (
			$filter->filter_name,
			$filter->desc,
		);
	}

	$clist->thaw;
	
	1;
}

sub init_selected_filters_list {
	my $self = shift;

	my $title = $self->comp('project')->selected_title;
	my $clist = $self->gtk_widgets->{"selected_filters_clist"};

	my $filters = Video::DVDRip::FilterList->get_filter_list;
	my $tc_filter_settings = $title->tc_filter_settings;

	$clist->freeze;
	$clist->clear;

	my $selected_filters = $tc_filter_settings->get_selected_filters;

	my $tc_filter_setting_id =
		$self->comp('project')
		     ->selected_title
		     ->tc_filter_setting_id;

	my ($i, $selected_row);
	
	foreach my $queue ( 'pre', 'post' ) {
		my $filter;
		$clist->append (
			"---------------",
			uc($queue),
			$queue
		);		
		++$i;
		foreach my $filter_instance ( @{$selected_filters} ) {
			eval {
				$filter = $filter_instance->get_filter;
			};
			next if $@;	# if a filter doesn't exist anymore
			next if $filter_instance->queue ne $queue;
			$clist->append (
				$filter->filter_name,
				$filter->desc,
				$filter_instance->id,
			);

			$selected_row = $i
				if $filter_instance->id == $tc_filter_setting_id;

			++$i;
		}

	}

	$clist->select_row ($selected_row, 0);

	$clist->thaw;
	
	1;
}

sub select_available_filter {
	my $self = shift; $self->trace_in;
	my ($clist, $row, $column, $event) = @_;

	$self->set_current_available_row ( $row );

	if ( defined $self->current_selected_row ) {
		$self->gtk_widgets
		     ->{selected_filters_clist}
		     ->unselect_row ( $self->current_selected_row, 0 );
	}

	$self->comp('project')
	     ->selected_title
	     ->set_tc_filter_setting_id ( undef );

	$self->update_filter_info (
		filter_name => $clist->get_text ( $row, 0 )
	);

	if ( $event->{type} eq '2button_press' ) {
		$self->add_filter;
	}

	1;
}

sub unselect_available_filter {
	my $self = shift; $self->trace_in;
	my ($clist, $row, $column, $event) = @_;

	$self->set_current_available_row ( undef );

	$self->comp('project')
	     ->selected_title
	     ->set_tc_filter_setting_id ( undef );

	$self->update_filter_info;

	1;
}

sub select_selected_filter {
	my $self = shift; $self->trace_in;
	my ($clist, $row, $column, $event) = @_;

	my $id = $clist->get_text ( $row, 2 );

	return $self->unselect_selected_filter
		if $id eq "pre" or $id eq "post";

	$self->set_current_selected_row ( $row );

	if ( defined $self->current_available_row ) {
		$self->gtk_widgets
		     ->{available_filters_clist}
		     ->unselect_row ( $self->current_available_row, 0 );
	}

	$self->comp('project')
	     ->selected_title
	     ->set_tc_filter_setting_id( $id );

	$self->update_filter_info (
		filter_id => $id,
	);

	if ( $event->{type} eq '2button_press' ) {
		$self->del_filter;
	}

	1;
}

sub unselect_selected_filter {
	my $self = shift; $self->trace_in;
	my ($clist, $row, $column, $event) = @_;

	$self->set_current_selected_row ( undef );

	$self->comp('project')
	     ->selected_title
	     ->set_tc_filter_setting_id( undef );

	$self->update_filter_info;

	1;
}

sub add_filter {
	my $self = shift;
	
	my $from_clist = $self->gtk_widgets->{available_filters_clist};
	my $to_clist   = $self->gtk_widgets->{selected_filters_clist};

	my ($row) = $from_clist->selection;
	
	return 1 if not defined $row;

	my $filter_name = $from_clist->get_text ( $row, 0 );

	my $title = $self->comp('project')->selected_title;

	my $filter_instance = $title->tc_filter_settings->add_filter (
		filter_name => $filter_name,
	);

	my $added_row = 0;
	if ( $filter_instance->queue eq 'pre' ) {
		while ( $to_clist->get_text ($added_row, 2) ne 'post' ) {
			++$added_row;
		}
		$to_clist->insert (
			$added_row,
			$from_clist->get_text ( $row, 0 ),
			$from_clist->get_text ( $row, 1 ),
			$filter_instance->id,
		);
	} else {
		$added_row = $to_clist->append (
			$from_clist->get_text ( $row, 0 ),
			$from_clist->get_text ( $row, 1 ),
			$filter_instance->id,
		);
	}

	$from_clist->remove ($row)
		if not Video::DVDRip::FilterList
			->get_filter ( filter_name => $filter_name )
			->can_multiple;

	$to_clist->select_row ( $added_row , 0 );

	1;
}

sub del_filter {
	my $self = shift;
	
	my $from_clist = $self->gtk_widgets->{selected_filters_clist};
	my $to_clist   = $self->gtk_widgets->{available_filters_clist};

	my ($row) = $from_clist->selection;
	
	return 1 if not defined $row;

	my $filter_name = $from_clist->get_text ( $row, 0 );
	my $filter_id   = $from_clist->get_text ( $row, 2 );

	return if $filter_id == 0;	# no pre/post marker removal

	my $title = $self->comp('project')->selected_title;

	if ( not $self->preview->closed ) {
		$self->preview->transcode_remote->disable_filter (
			filter => $title->tc_filter_settings
					->get_filter_instance ( id => $filter_id )
					->filter_name
		);
	}

	$title->tc_filter_settings->del_filter (
		id => $filter_id,
	);
	
	if ( not Video::DVDRip::FilterList
		->get_filter ( filter_name => $filter_name )
		->can_multiple ) {

		my $target_row = 0;
		while ( $to_clist->get_text ( $target_row, 0 ) ne '' and
			$to_clist->get_text ( $target_row, 0 ) lt $filter_name ) {
			++$target_row;
		}

		$to_clist->insert (
			$target_row, 
			$from_clist->get_text ( $row, 0 ),
			$from_clist->get_text ( $row, 1 ),
		);	
	}

	$from_clist->remove ($row);
	--$row if not $from_clist->get_text ( $row, 2 );
	$from_clist->select_row ($row, 0);

	1;
}

sub reorder_selected_filter {
	my $self = shift;
	my ($clist, $from_row, $to_row) = @_;

	my $title = $self->comp('project')->selected_title;

	my $d = $from_row > $to_row ? 0 : 1;

	my $id        = $clist->get_text ( $from_row,  2 );
	my $before_id = $clist->get_text ( $to_row+$d, 2 );

	my $success;
	
	if ( not $self->preview->closed ) {
		$self->message_window (
			message =>
				"You can't change the filter order\n".
				"while the preview window is open."
		);
		$success = 0;
	} else {
		$success = $title->tc_filter_settings->move_instance (
			id        => $id,
			before_id => $before_id,
		);
	}

	if ( not $success ) {
		# workaround: modifiying the clist in a "reorder in progress"
		# state doesn't work. No way. Never. Don't ask my why.
		Gtk->idle_add( sub {
			$self->init_selected_filters_list;
			0;
		} );
	}
	
	1;
}

sub update_filter_info {
	my $self = shift;
	my %par = @_;
	my  ($filter_id, $filter_name) =
	@par{'filter_id','filter_name'};

	my $widgets = $self->gtk_widgets;

	$widgets->{filter_info_vbox}->remove (
		$widgets->{filter_info_widget}
	);

	if ( not $filter_id and not $filter_name ) {
		my $label = Gtk::Label->new ("No filter selected.");
		$label->show;
		$widgets->{filter_info_vbox}->pack_start ($label, 0, 1, 0);
		$widgets->{filter_info_widget} = $label;
		$self->build_filter_settings;
		return 1;
	}

	my $filter_instance;
	if ( $filter_id ) {
		my $title = $self->comp('project')->selected_title;
		$filter_instance =
			$title->tc_filter_settings
			      ->get_filter_instance ( id => $filter_id );
		$filter_name = $filter_instance->filter_name;
	}

	my $filter = Video::DVDRip::FilterList
			->get_filter ( filter_name => $filter_name );

	my $info = $filter->get_info;
	
	my $table = Gtk::Table->new ( 1, 2, 0 );
	$table->set_col_spacings ( 4 );
	$table->show;
	
	my $i = 0;
	my ($label, $hbox, $vbox);
	foreach my $item ( @{$info} ) {
		$label = Gtk::Label->new ($item->[0].":");
		$label->show;
		$hbox = Gtk::HBox->new;
		$hbox->show;
		$hbox->pack_start($label, 0, 1, 0);
		$vbox = Gtk::VBox->new;
		$vbox->show;
		$vbox->pack_start($hbox, 0, 1, 0);
		$table->attach_defaults ($vbox, 0, 1, $i, $i+1);
		$label = Gtk::Label->new ($item->[1]);
		$label->set_line_wrap(1);
		$label->show;
		$hbox = Gtk::HBox->new;
		$hbox->show;
		$hbox->pack_start($label, 0, 1, 0);
		$table->attach_defaults ($hbox, 1, 2, $i, $i+1);
		++$i;
	}
	
	$widgets->{filter_info_vbox}->pack_start ($table, 0, 1, 0);
	$widgets->{filter_info_widget} = $table;
	
	$self->build_filter_settings (
		filter          => $filter,
		filter_instance => $filter_instance
	);

	Video::DVDRip::GUI::Setting->update_object_settings (
		name => "title",
	);
	Video::DVDRip::GUI::Setting->update_object_settings (
		name => "filter_setting",
	);
	Video::DVDRip::GUI::Setting->update_object_settings (
		name => "filter_options",
	);

	1;
}

sub build_filter_settings {
	my $self = shift;
	my %par = @_;
	my  ($filter, $filter_instance) =
	@par{'filter','filter_instance'};

	my $sw = $self->gtk_widgets->{filter_options_sw};
	$sw->remove ( $sw->children );

	my $row = 0;
	my $table = Gtk::Table->new ( 2, 1, 0 );
	$table->show;
	$table->set_row_spacings ( 4 );
	$table->set_col_spacings ( 10 );

	my $vbox = Gtk::VBox->new;
	$vbox->show;
	$vbox->set_border_width(5);
	$vbox->pack_start ($table, 0, 1, 0);
	$sw->add_with_viewport ($vbox);

	return 1 if not $filter;

	Video::DVDRip::GUI::Setting::Checkbox->new (
		name		=> "filter_enabled",
		table		=> $table,
		row		=> $row++,
		object		=> "filter_setting",
		attr		=> "enabled",
		label		=> "Enable filter",
		tooltip		=> "Disable filter temporarily",
	);

	my $sep = Gtk::HSeparator->new;
	$sep->show;
	$table->attach_defaults ( $sep, 0, 2, $row, $row+1 );

	++$row;

	foreach my $option ( @{$filter->options} ) {

		next if $option->option_name eq 'pre';

		my $setting = $self->build_option_field (
			option		=> $option,	        
			field		=> $option->fields->[0],	        
			idx		=> 0,	        
			table		=> $table,	        
			row		=> $row++,	        
		);

		my $idx = -1;
		foreach my $field ( @{$option->fields} ) {
			++$idx;
			next if $idx == 0;

			$self->build_option_field (
				option		=> $option,	        
				field		=> $option->fields->[$idx],
				idx		=> $idx,	        
				table		=> $table,	        
				row		=> $row,
				widget_hbox	=> $setting->widget_hbox,	        
			);
		}
	}

	if ( not @{$filter->options} ) {
		my $label = Gtk::Label->new ("This filter has no options");
		$label->show;
		my $hbox = Gtk::HBox->new;
		$hbox->show;
		$hbox->pack_start ($label, 0, 1, 0);
		$table->attach_defaults ($hbox, 0, 1, $row, $row+1);
	}

	1;
}

sub build_option_field {
	my $self = shift;
	my %par = @_;
	my  ($option, $field, $idx, $table, $row, $widget_hbox) =
	@par{'option','field','idx','table','row','widget_hbox'};

	my $option_name = $option->option_name;

	my $is_min = $field->range_from;
	my $is_max = $field->range_to;

	my $label;
	if ( $widget_hbox ) {
		$table = undef;
	} else {
		$label = $option->get_wrapped_desc;
	}

	my $setting;
	if ( $field->checkbox or $field->switch ) {
		$setting = Video::DVDRip::GUI::Setting::Checkbox->new (
			name		=> "filter_option_".$option_name."_$idx",
			table		=> $table,
			row		=> $row,
			box		=> $widget_hbox,
			object		=> "filter_options",
			label		=> $label,
			tooltip		=> $field->get_range_text,
			args		=> { option_name => $option_name, idx => $idx },
		);
	} else {
		my $presets;
		if ( $field->combo ) {
			my @presets = ( $field->range_from .. $field->range_to );
			$presets = \@presets;
		}

		my $is_number = 1;

		if ( $option->fields->[$idx]->text ) {
			$is_number = 0;
			$is_min = $is_max = undef;
		}

		$setting = Video::DVDRip::GUI::Setting::Text->new (
			name		=> "filter_option_".$option_name."_$idx",
			table		=> $table,
			row		=> $row,
			box		=> $widget_hbox,
			usize		=> ($option->fields->[$idx]->text ? 100 : undef),
			object		=> "filter_options",
			label		=> $label,
			presets		=> $presets,
			tooltip		=> $field->get_range_text,
			args		=> { option_name => $option_name, idx => $idx },

			is_number 	=> $is_number,
			is_min		=> $is_min,
			is_max		=> $is_max,
			may_negative    => $is_min < 0,
			may_fractional 	=> $field->fractional,
			may_empty	=> 1,
		);
		
		$widget_hbox ||= $setting->widget_hbox;
		
		if ( $option->fields->[$idx]->text ) {
			my $button = Gtk::Button->new ("...");
			$button->new;
			$button->show;
			$widget_hbox->pack_start ($button, 0, 1, 0);
			$button->signal_connect ("clicked", sub {
				$self->show_file_dialog (
					dir      => $ENV{HOME},
					filename => "",
					cb       => sub {
						$setting->widget->set_text ($_[0]);
					},
				);
				1;
			});
		}
	}

	return $setting;

}

sub preview_play {
	my $self = shift;

	return 1 if $self->stop_in_progress;
	
	my $widgets = $self->gtk_widgets;

	$widgets->{preview_play_button}->set_sensitive ( 0 );
	$widgets->{preview_stop_button}->set_sensitive ( 1 );
	$widgets->{preview_pause_button}->set_sensitive ( 1 );
	$widgets->{preview_apply_button}->set_sensitive ( 1 );
	$widgets->{preview_faster_button}->set_sensitive ( 1 );
	$widgets->{preview_slower_button}->set_sensitive ( 1 );

	$self->preview->open;

	$self->set_playing(1);

	1;
}

sub preview_stop{
	my $self = shift;
	my %par = @_;
	my ($reset_gui_only) = @par{'reset_gui_only'};
	
	my $widgets = $self->gtk_widgets;

	$self->set_stop_in_progress ( 1 );

	if ( not $reset_gui_only ) {
		$self->preview->stop;
	}

	$widgets->{preview_slow_rewind_button}->set_sensitive ( 0 );
	$widgets->{preview_slow_forward_button}->set_sensitive ( 0 );
	$widgets->{preview_fast_rewind_button}->set_sensitive ( 0 );
	$widgets->{preview_fast_forward_button}->set_sensitive ( 0 );

	$widgets->{preview_play_button}->set_sensitive ( 1 );
	$widgets->{preview_stop_button}->set_sensitive ( 0 );
	$widgets->{preview_pause_button}->set_sensitive ( 0 );

	$widgets->{preview_pause_button}->child->set ( "||" )
		if $widgets->{preview_pause_button}->child;

	$widgets->{preview_apply_button}->set_sensitive ( 0 );
	$widgets->{preview_undo_button}->set_sensitive ( 0 );

	$widgets->{preview_faster_button}->set_sensitive ( 0 );
	$widgets->{preview_slower_button}->set_sensitive ( 0 );

	$widgets->{preview_play_button}->set_active ( 0 );
	$widgets->{preview_pause_button}->set_active ( 0 );
	$widgets->{preview_undo_button}->set_active ( 0 );

	$self->set_stop_in_progress ( 0 );

	$self->set_playing(0);

	1;
}

sub preview_slower {
	my $self = shift;

	$self->preview->transcode_remote->preview (
		command => "slower",
	);
	
	1;
}

sub preview_faster {
	my $self = shift;
	
	$self->preview->transcode_remote->preview (
		command => "faster",
	);
	
	1;
}

sub preview_pause {
	my $self = shift;
	
	return 1 if $self->stop_in_progress;

	my $widgets = $self->gtk_widgets;
	
	my $paused = $self->preview->pause;

	$widgets->{preview_slow_rewind_button}->set_sensitive ( $paused );
	$widgets->{preview_slow_forward_button}->set_sensitive ( $paused );
	$widgets->{preview_fast_rewind_button}->set_sensitive ( $paused );
	$widgets->{preview_fast_forward_button}->set_sensitive ( $paused );

#	$widgets->{preview_apply_button}->set_sensitive ( ! $paused );

	$widgets->{preview_undo_button}->set_sensitive ( 0 )
		if not $paused;

	$self->set_pause_in_progress ( 1 );
	$widgets->{preview_undo_button}->set_active ( 0 );
	$self->set_pause_in_progress ( 0 );

	$widgets->{preview_pause_button}->child->set (
		$paused ? "|| >" : "||"
	);

	1;
}

sub preview_slow_rewind {
	my $self = shift;
	
	$self->preview->transcode_remote->preview (
		command => "slowbw",
	);
	
	1;
}

sub preview_slow_forward {
	my $self = shift;
	
	$self->preview->transcode_remote->preview (
		command => "slowfw",
	);
	
	1;
}

sub preview_fast_rewind {
	my $self = shift;
	
	$self->preview->transcode_remote->preview (
		command => "fastbw",
	);
	
	1;
}

sub preview_fast_forward {
	my $self = shift;
	
	$self->preview->transcode_remote->preview (
		command => "fastfw",
	);
	
	1;
}

sub preview_apply {
	my $self = shift;
	
	$self->preview->apply_filter_settings;

	if ( $self->preview->transcode_remote->paused ) {
		$self->gtk_widgets->{preview_undo_button}->set_sensitive ( 1 );
	}

	1;
}

sub preview_undo {
	my $self = shift;
	
	return 1 if $self->pause_in_progress;
	return 1 if $self->stop_in_progress;
	
	my $title            = $self->comp('project')->selected_title;
	my $transcode_remote = $self->preview->transcode_remote;
	
	if ( $self->gtk_widgets->{preview_undo_button}->active ) {
		$transcode_remote->preview ( command => "undo" );
	} else {
		my $max_frames_needed =
			$title->tc_filter_settings
			      ->get_max_frames_needed;
		$transcode_remote->preview (
			command => "draw",
			options => $max_frames_needed,
		);
	}
	
	1;
}

sub preview_selection {
	my $self = shift;
	my %par = @_;
	my  ($x1, $y1, $x2, $y2) =
	@par{'x1','y1','x2','y2'};

	my $title = $self->comp('project')->selected_title;
	my $filter_setting = $title->tc_selected_filter_setting;
	my $filter = $filter_setting->get_filter;
	
	my $selection_cb = $filter->get_selection_cb;
	return 1 if not $selection_cb;

	($x1, $x2) = ($x2, $x1) if $x1 > $x2;
	($y1, $y2) = ($y2, $y1) if $y1 > $y2;

	if ( $filter_setting->queue eq 'pre' ) {
		# transform back values => undo resizing & clipping
		
		# undo 2nd clip
		$x1 += $title->tc_clip2_left;
		$y1 += $title->tc_clip2_top;
		$x2 += $title->tc_clip2_left;
		$y2 += $title->tc_clip2_top;
		
		# undo resize
		my $width_factor = $title->tc_zoom_width /
				   ( $title->width - $title->tc_clip1_left
				   		   - $title->tc_clip1_right );
		my $height_factor = $title->tc_zoom_height/
				   ( $title->height - $title->tc_clip1_top
				   		    - $title->tc_clip1_bottom );
		$x1 = int ($x1 / $width_factor );
		$x2 = int ($x2 / $width_factor );
		$y1 = int ($y1 / $height_factor );
		$y2 = int ($y2 / $height_factor );
		
		# undo 1st clip
		$x1 += $title->tc_clip1_left;
		$y1 += $title->tc_clip1_top;
		$x2 += $title->tc_clip1_left;
		$y2 += $title->tc_clip1_top;
	}

	if ( $title->tc_use_yuv_internal ) {
		foreach my $x ( $x1, $x2, $y1, $y2 ) {
			$x = int($x/2)*2;
		}
	}

	&$selection_cb (
		filter_setting	=> $filter_setting,
		x1		=> $x1,
		y1		=> $y1,
		x2		=> $x2,
		y2		=> $y2,
	);

	Video::DVDRip::GUI::Setting->update_object_settings (
		name => "filter_options",
	);

	$self->preview_apply;

	1;
}

1;
