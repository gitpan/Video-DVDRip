# $Id: BurnTab.pm,v 1.5.2.1 2002/11/23 13:41:34 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
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

sub burn_widgets		{ shift->{burn_widgets} 		}
sub set_burn_widgets		{ shift->{burn_widgets}		= $_[1]	}

sub burn_files			{ shift->{burn_files}			}
sub set_burn_files		{ shift->{burn_files}		= $_[1]	}

sub sum_mb			{ shift->{sum_mb}			}
sub set_sum_mb			{ shift->{sum_mb}		= $_[1]	}

#------------------------------------------------------------------------
# Build RIP Title Tab
#------------------------------------------------------------------------

sub create_burn_tab {
	my $self = shift; $self->trace_in;

	$self->set_burn_widgets({});

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
	my $cd_type = $self->create_burn_cd_type (
		hsize_group => $left_hsize_group
	);
	my $files = $self->create_burn_files (
		hsize_group => $left_hsize_group
	);
	my $label = $self->create_burn_label (
		hsize_group => $left_hsize_group
	);
	my $options = $self->create_burn_options (
		hsize_group => $left_hsize_group
	);
	my $operate = $self->create_burn_operate (
		hsize_group => $left_hsize_group
	);

	# Put frames into table
	my $table = Gtk::Table->new ( 5, 1, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$vbox->pack_start ($table, 0, 1, 0);

	$table->attach_defaults ($cd_type, 	0, 1, 0, 1);
	$table->attach_defaults ($files, 	0, 1, 1, 2);
	$table->attach_defaults ($label, 	0, 1, 2, 3);
	$table->attach_defaults ($options, 	0, 1, 3, 4);
	$table->attach_defaults ($operate, 	0, 1, 4, 5);

	return $vbox;
}

sub create_burn_cd_type {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->burn_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries);

	# Frame
	$frame = Gtk::Frame->new ("CD type selection");
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

	# Select CD type
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Select a CD type    ");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $ogg = $self->config('ogg_file_ext');
	my $radio_iso = Gtk::RadioButton->new ("ISO 9660 (.avi and .$ogg files)   ");
	$radio_iso->show;
	$hbox->pack_start($radio_iso, 0, 1, 0);
	my $radio_svcd = Gtk::RadioButton->new ("SVCD (.mpg files)   ", $radio_iso);
	$radio_svcd->show;
	$hbox->pack_start($radio_svcd, 0, 1, 0);
	my $radio_vcd = Gtk::RadioButton->new ("VCD (.mpg files)   ", $radio_iso);
	$radio_vcd->show;
	$hbox->pack_start($radio_vcd, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$widgets->{burn_cd_type_iso}   = $radio_iso;
	$widgets->{burn_cd_type_vcd}   = $radio_vcd;
	$widgets->{burn_cd_type_svcd}  = $radio_svcd;

	$radio_iso->signal_connect ("clicked", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_cd_type ("iso");
		$self->init_burn_files;
		1;
	});
	$radio_vcd->signal_connect ("clicked", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_cd_type ("vcd");
		$self->init_burn_files;
		1;
	});
	$radio_svcd->signal_connect ("clicked", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_cd_type ("svcd");
		$self->init_burn_files;
		1;
	});

	return $frame;
}

sub create_burn_files {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->burn_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new ("File selection");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 1, 1, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# File selection list
	$row = 0;

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	my $clist = Gtk::CList->new_with_titles (
		"Filename", "Size (MB)"
	);
	$clist->show,
	$clist->set_usize (undef, 150);
	$clist->set_column_width( 0, 500 );
 	$clist->set_selection_mode( 'extended' ); 
	$clist->signal_connect ("select_row",   sub {
		$self->cb_select_burn_title (@_);
	} );
	$clist->signal_connect ("unselect_row", sub {
		$self->cb_select_burn_title (@_);
	} );

	$sw->add( $clist );

	$table->attach_defaults ($sw, 0, 1, $row, $row+1);

	$widgets->{file_content_clist} = $clist;

	# Table
	$table = Gtk::Table->new ( 1, 5, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Megabytes selected
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("MB selected");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ('0 MB');
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{mb_selected_label} = $label;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("     Free diskspace");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ('0 MB');
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 3, 4, $row, $row+1, 'fill','expand',0,0);

	$widgets->{free_diskspace_mb} = $label;

	# Buttons
	my $align = Gtk::Alignment->new ( 1, 0, 0, 1);
	$align->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$align->add ($hbox);
	$table->attach_defaults ($align, 4, 5, $row, $row+1);

	# Delete Button
	$button = Gtk::Button->new (" Delete selected file ");
	$button->show;
	$button->set_sensitive(0);
	$hbox->pack_start ($button, 0, 1, 0);

	$widgets->{delete_file_button} = $button;
	$button->signal_connect ("clicked", sub { $self->ask_delete_selected_burn_file } );

	# View Button
	$button = Gtk::Button->new (" View selected file ");
	$button->show;
	$button->set_sensitive(0);
	$hbox->pack_start ($button, 0, 1, 0);

	$widgets->{view_file_button} = $button;
	$button->signal_connect ("clicked", sub { $self->view_selected_burn_file } );

	return $frame;
}

sub create_burn_label {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->burn_widgets;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $checkbox);

	# Frame
	$frame = Gtk::Frame->new ("Label information");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::HBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Table
	$table = Gtk::Table->new ( 2, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# CD Label
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Label");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(250,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$widgets->{cd_label} = $entry;

	# CD Abstract
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Abstract");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(250,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$widgets->{cd_abstract} = $entry;

	$checkbox = Gtk::CheckButton->new;
	$checkbox->show;
	$hbox->pack_start($checkbox, 0, 1, 0);

	$widgets->{cd_abstract_sticky} = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_abstract_sticky ($_[0]->get_active);
		1;
	});

	$label = Gtk::Label->new ("   Number");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$widgets->{cd_number} = $entry;

	$widgets->{cd_label}->signal_connect ("changed", sub {
		return if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_label ($_[0]->get_text);
		1;
	});
	$widgets->{cd_abstract}->signal_connect ("changed", sub {
		return if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_abstract ($_[0]->get_text);
		1;
	});
	$widgets->{cd_number}->signal_connect ("changed", sub {
		return if $self->in_transcode_init;
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_burn_number ($_[0]->get_text);
		1;
	});

	return $frame;
}

sub create_burn_options {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->burn_widgets;

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
	$table = Gtk::Table->new ( 2, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Test mode
	$row = 0;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Test mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $checkbox = Gtk::CheckButton->new ("Simulate burning");
	$checkbox->show;
	$hbox->pack_start ($checkbox, 1, 1, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);
	$widgets->{test_mode} = $checkbox;

	$checkbox->signal_connect ("toggled", sub {
		return 1 if $self->in_transcode_init;
		$self->config_object->set_value (
			burn_test_mode => $_[0]->active
		);
		$self->config_object->save;
		1;
	});

	# Writing speed
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Writing speed");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedCombo->new (
		is_number      => 1,
		may_fractional => 0,
		may_empty      => 0,
	);
	$entry->show;
	$entry->set_popdown_strings (1,2,4,8,12,16,20,24,30,40);
	$entry->set_usize(60,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{writing_speed} = $entry;

	$entry->entry->signal_connect ("focus-out-event", sub {
		return 1 if $self->in_transcode_init;
		$self->config_object->set_value (
			burn_writing_speed => $_[0]->get_text
		);
		$self->config_object->save;
		1;
	});

	return $frame;
}

sub create_burn_operate {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my $widgets = $self->burn_widgets;

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
	$frame_hbox->pack_start ($button_box, 0, 1, 0);

	# Burn Button
	$button = Gtk::Button->new_with_label ("  Burn selected file(s)  ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->burn_cd } );
	$button_box->add ($button);

	$widgets->{burn_button} = $button;

	# Image Button
	$button = Gtk::Button->new_with_label ("  Create CD image from selected file(s) ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->create_cd_image } );
	$button_box->add ($button);

	$widgets->{image_button} = $button;

	return $frame;
}

sub init_burn_values {
	my $self = shift; $self->trace_in;

	$self->set_in_transcode_init(1);

	my $widgets = $self->burn_widgets;
	my $title   = $self->selected_title;
	return 1 if not $title;
	
	my $cd_type = $title->burn_cd_type;

	$widgets->{writing_speed}->entry->set_text ($self->config('burn_writing_speed'));
	$widgets->{test_mode}->set_active ($self->config('burn_test_mode'));
	$widgets->{cd_label}->set_text($title->burn_label);
	$widgets->{cd_abstract}->set_text($title->burn_abstract);
	$widgets->{cd_number}->set_text($title->burn_number);
	$widgets->{cd_abstract_sticky}->set_active($title->burn_abstract_sticky);
	$widgets->{burn_cd_type_iso}->set_active(1) if $cd_type eq 'iso';
	$widgets->{burn_cd_type_vcd}->set_active(1)  if $cd_type eq 'vcd';
	$widgets->{burn_cd_type_svcd}->set_active(1) if $cd_type eq 'svcd';

	$self->set_in_transcode_init(0);
	
	1;
}

sub init_burn_files {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	$self->set_in_transcode_init(1);

	my $free = $title->get_free_diskspace;

	$self->burn_widgets->{mb_selected_label}->set_text ("0 MB");
	$self->burn_widgets->{free_diskspace_mb}->set_text("$free MB");
	$self->burn_widgets->{view_file_button}->set_sensitive(0);
	$self->burn_widgets->{delete_file_button}->set_sensitive(0);

	my $files_lref = $title->get_burn_files;
	$self->set_burn_files ( $files_lref );

	my $clist          = $self->burn_widgets->{file_content_clist};
	my $selected_files = $title->burn_files_selected;

	$clist->freeze;
	$clist->clear;

	my $row = 0;
	my $something_selected = 0;
	foreach my $file ( @{$files_lref} ) {
		$clist->append ($file->{name},$file->{size});
		$clist->select_row ($row, 0) if $selected_files->{$file->{name}};
		$something_selected = 1 if $selected_files->{$file->{name}};
		++$row;
	}

	$clist->thaw;

	$self->cb_select_burn_title ( dont_save_selection => 1 )
		if $row == 0 or not $something_selected;

	$self->set_in_transcode_init(0);
	
	1;
}

sub cb_select_burn_title {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($dont_save_selection) =
	@par{'dont_save_selection'};

	my $title   = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->burn_widgets;
	my $clist   = $widgets->{file_content_clist};
	my $cd_type = $title->burn_cd_type;

	my @sel                 = $clist->selection;
	my $burn_files          = $self->burn_files;
	my $selected_burn_files = {};

	my $sum_mb = 0;
	my $selected_file;

	my $is_image    = 0;
	my $no_image    = 0;
	my $image_mixed = 0;

	foreach my $row ( @sel ) {
		$selected_file = $burn_files->[$row];
		$sum_mb += $selected_file->{size};
		$selected_burn_files->{$selected_file->{name}} = $burn_files->[$row];

		++$is_image if     $selected_file->{is_image};
		++$no_image if not $selected_file->{is_image};
	}

	$widgets->{mb_selected_label}->set_text ($sum_mb. " MB");

	$self->set_sum_mb ( $sum_mb );

	$title->set_burn_files_selected($selected_burn_files)
		if not $dont_save_selection;

	if ( @sel == 1 ) {
		$widgets->{cd_label}->set_text ($selected_file->{label});
		$widgets->{cd_abstract}->set_text ($selected_file->{abstract})
			if not $widgets->{cd_abstract_sticky}->get_active;
		$widgets->{cd_number}->set_text ($selected_file->{number});

		$widgets->{view_file_button}->set_sensitive(not $is_image);
		$widgets->{delete_file_button}->set_sensitive(1);
	} else {
		$widgets->{view_file_button}->set_sensitive(0);
		$widgets->{delete_file_button}->set_sensitive(0);
	}

	my $image_button = 1;
	my $burn_button  = 1;

	$image_mixed  = 1 if $is_image > 1 or $is_image and $no_image;

	$image_button = 0 if $is_image or @sel == 0;
	$burn_button  = 0 if $image_mixed or @sel == 0;
	$burn_button  = 0 if not $is_image and $cd_type ne 'iso';

	$widgets->{burn_button}  ->set_sensitive ($burn_button );
	$widgets->{image_button} ->set_sensitive ($image_button);
	$widgets->{cd_label}     ->set_sensitive ($image_button);
	$widgets->{cd_abstract}  ->set_sensitive ($image_button);
	$widgets->{cd_number}    ->set_sensitive ($image_button);

	if ( not $image_button ) {
		$widgets->{cd_label}->set_text("");
		$widgets->{cd_abstract}->set_text("")
			if not $widgets->{cd_abstract_sticky}->get_active;
		$widgets->{cd_number}->set_text("");
  	}

	1;
}

sub view_selected_burn_file {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $selected_files = $title->burn_files_selected;
	my $filename = $selected_files
			    ->{(keys %{$selected_files})[0]}
			    ->{path};

	my $command = $title->get_view_avi_command (
		command_tmpl => $self->config('play_file_command'),
		file => $filename,
	);

	system ($command." &");
}

sub ask_delete_selected_burn_file {
	my $self = shift;
	
	my $title = $self->selected_title;
	return 1 if not $title;

	my $selected_files = $title->burn_files_selected;
	my $path = $selected_files
			    ->{(keys %{$selected_files})[0]}
			    ->{path};

	my $filename = basename($path);

	$self->confirm_window (
		message => "Do you want to delete the file $filename?",
		yes_label => "Yes",
		yes_callback => sub {
			$self->delete_selected_burn_file (
				filename => $path
			);
		},
	);

	1;
}

sub delete_selected_burn_file {
	my $self = shift;
	my %par = @_;
	my ($filename) = @par{'filename'};

	$self->log ("Deleting file $filename");
	
	unlink ($filename);
	
	$self->init_burn_files;
	$self->cb_select_burn_title;
	$self->comp('progress')->set_idle_label;

	1;
}

sub create_cd_image {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;

	my $nr;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;
	my $job  = Video::DVDRip::Job::CreateCDImage->new (
		nr    => ++$nr,
		title => $title,
	);
	$job->set_on_the_fly(0);
	$job->set_max_size ( $self->sum_mb );

	$last_job = $exec->add_job ( job => $job );

	$exec->set_cb_finished (sub{
		$self->init_burn_files;
		1;
	});

	$exec->execute_jobs;

	1;
}

sub burn_cd {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->comp('progress')->is_active;

	my $nr;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;
	my $job  = Video::DVDRip::Job::BurnCD->new (
		nr    => ++$nr,
		title => $title,
	);
	$job->set_test_mode ($self->config('burn_test_mode'));
	$job->set_max_size ( $self->sum_mb );

	$last_job = $exec->add_job ( job => $job );

	$exec->execute_jobs;

	1;
}

1;
