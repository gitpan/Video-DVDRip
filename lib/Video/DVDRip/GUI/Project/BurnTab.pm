# $Id: BurnTab.pm,v 1.16 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

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
	$vbox->pack_start ($table, 1, 1, 0);

	$table->attach ($cd_type, 	0, 1, 0, 1, ['fill','expand'], [], 0, 0);
	$table->attach_defaults ($files, 	0, 1, 1, 2);
	$table->attach ($label, 	0, 1, 2, 3, ['fill','expand'], [], 0, 0);
	$table->attach ($options, 	0, 1, 3, 4, ['fill','expand'], [], 0, 0);
	$table->attach ($operate, 	0, 1, 4, 5, ['fill','expand'], [], 0, 0);

	my $sensitive = ( $self->has ("mkisofs") &&
			  $self->has ("cdrecord") ) ||
			( $self->has ("vcdimager") &&
			  $self->has ("cdrdao") );

	$table->set_sensitive($sensitive);

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
	$frame = Gtk::Frame->new (__"CD type selection");
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
#	$label = Gtk::Label->new (__"Select a CD type");
#	$label->show;
#	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	# $hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $ogg = $self->config('ogg_file_ext');
	my $radio_iso = Gtk::RadioButton->new (__x("ISO 9660 (.avi and .{ogg_ext} files)", ogg_ext => $ogg)."   ");
	$radio_iso->show;
	$radio_iso->set_sensitive(0) if not $self->has ("mkisofs") or
					not $self->has ("cdrecord");
	$hbox->pack_start($radio_iso, 0, 1, 0);
	my $radio_svcd = Gtk::RadioButton->new (__("(X)SVCD/CVD (.mpg files)")."   ", $radio_iso);
	$radio_svcd->show;
	$radio_svcd->set_sensitive(0) if not $self->has ("vcdimager") or
					 not $self->has ("cdrdao");
	$hbox->pack_start($radio_svcd, 0, 1, 0);
	my $radio_vcd = Gtk::RadioButton->new (__("(X)VCD (.mpg files)")."   ", $radio_iso);
	$radio_vcd->show;
	$radio_vcd->set_sensitive(0) if not $self->has ("vcdimager") or
					not $self->has ("cdrdao");
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

	my ($frame, $frame_vbox, $table, $row, $hbox, $label, $entry);
	my ($popup_menu, $popup, $item, %popup_entries, $button);

	# Frame
	$frame = Gtk::Frame->new (__"File selection");
	$frame->show;

	# Frame VBox
	$frame_vbox = Gtk::VBox->new;
	$frame_vbox->set_border_width(5);
	$frame_vbox->show;
	$frame->add ($frame_vbox);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	my $clist = Gtk::CList->new_with_titles (
		__"Filename", __"Size (MB)"
	);
	$clist->show,
#	$clist->set_usize (undef, 150);
	$clist->set_column_width( 0, 500 );
 	$clist->set_selection_mode( 'extended' ); 
 	$clist->column_titles_passive;
	$clist->signal_connect ("select_row",   sub {
		$self->cb_select_burn_title (@_);
	} );
	$clist->signal_connect ("unselect_row", sub {
		$self->cb_select_burn_title (@_);
	} );

	$sw->add( $clist );

	$frame_vbox->pack_start ($sw, 1, 1, 0);

	$widgets->{file_content_clist} = $clist;

	# Table
	$table = Gtk::Table->new ( 1, 5, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_vbox->pack_start ($table, 0, 0, 0);

	# Megabytes selected
	$row = 1;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new (__"MB selected");
	$label->show;
	$hbox->pack_start($label, 0, 0, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill',[],0,0);
	# $hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ('0 MB');
	$label->show;
	$hbox->pack_start($label, 0, 0, 0);
	$table->attach ($hbox, 1, 2, $row, $row+1, 'fill',[],0,0);

	$widgets->{mb_selected_label} = $label;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new (__"Free diskspace");
	$label->show;
	$hbox->pack_start($label, 0, 0, 0);
	$table->attach ($hbox, 2, 3, $row, $row+1, 'fill',[],0,0);
	# $hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ('0 MB');
	$label->show;
	$hbox->pack_start($label, 0, 0, 0);
	$table->attach ($hbox, 3, 4, $row, $row+1, 'fill',[],0,0);

	$widgets->{free_diskspace_mb} = $label;

	# Buttons
	my $align = Gtk::Alignment->new ( 1, 0, 0, 1);
	$align->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$align->add ($hbox);
	$table->attach ($align, 4, 5, $row, $row+1, ['expand','fill'], [], 0, 0);
#	$table->attach_defaults ($align, 4, 5, $row, $row+1);

	# Delete Button
	$button = Gtk::Button->new (__"Delete selected file");
	$button->show;
	$button->set_sensitive(0);
	$hbox->pack_start ($button, 0, 0, 0);

	$widgets->{delete_file_button} = $button;
	$button->signal_connect ("clicked", sub { $self->ask_delete_selected_burn_file } );

	# View Button
	$button = Gtk::Button->new (__"View selected file");
	$button->show;
	$button->set_sensitive(0);
	$hbox->pack_start ($button, 0, 0, 0);

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
	$frame = Gtk::Frame->new (__"Label information");
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
	# $hsize_group->add ($hbox);

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
	$label = Gtk::Label->new (__"Abstract");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	# $hsize_group->add ($hbox);

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

	$label = Gtk::Label->new (__"Number");
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
	$frame = Gtk::Frame->new (__"General options");
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
	$label = Gtk::Label->new (__"Test mode");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	# $hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	my $checkbox = Gtk::CheckButton->new (__"Simulate burning");
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
	$label = Gtk::Label->new (__"Writing speed");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	# $hsize_group->add ($hbox);

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

	$entry->entry->signal_connect ("changed", sub {
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
	my ($button, $button_box, $frame_vbox);

	# Frame
	$frame = Gtk::Frame->new (__"Operate");
	$frame->show;

	# Frame VBox
	$frame_vbox = Gtk::VBox->new;
	$frame_vbox->show;
	$frame_vbox->set_border_width(5);
	$frame->add ($frame_vbox);
	
	# ButtonBox
	$button_box = Gtk::HBox->new;
	$button_box->show;
	$frame_vbox->pack_start ($button_box, 0, 1, 0);

	# Burn Button
	$button = Gtk::Button->new_with_label (__"Burn selected file(s)");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->burn_cd } );
	$button_box->pack_start ($button, 0, 1, 0);

	$widgets->{burn_button} = $button;

	# Image Button
	$button = Gtk::Button->new_with_label (__"Create CD image from selected file(s)");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->create_cd_image } );
	$button_box->pack_start ($button, 0, 1, 0);

	$widgets->{image_button} = $button;

	# ButtonBox
	$button_box = Gtk::HBox->new;
	$button_box->show;
	$frame_vbox->pack_start ($button_box, 0, 1, 0);

	# Eject Button
	$button = Gtk::Button->new_with_label (__"Open burner tray");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->eject_media } );
	$button_box->pack_start ($button, 0, 1, 0);

	# Insert Button
	$button = Gtk::Button->new_with_label (__"Close burner tray");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->insert_media } );
	$button_box->pack_start ($button, 0, 1, 0);

	# Blank CD-RW button
	$button = Gtk::Button->new_with_label (__"Blank CD-RW");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->burn_cd ( erase_cdrw => 1 ) } );
	$button_box->pack_start ($button, 0, 1, 0);
	
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

	my $free = $title->project->get_free_diskspace;

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
		message => __x("Do you want to delete the file {filename}?", filename => $filename),
		yes_label => __"Yes",
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

	$self->log (__x("Deleting file {filename}", filename => $filename));
	
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
	my %par = @_;
	my ($erase_cdrw) = @par{'erase_cdrw'};

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
	$job->set_test_mode ( $self->config('burn_test_mode') );
	$job->set_erase_cdrw ( $erase_cdrw );
	$job->set_max_size ( $self->sum_mb );

	$last_job = $exec->add_job ( job => $job );

	$exec->execute_jobs;

	1;
}

sub eject_media {
        my $self = shift;

        my $command = $self->config('eject_command') . " " . $self->config('writer_device');

        system ("$command &");

        1;
}

sub insert_media {
        my $self = shift;

        my $command = $self->config('eject_command') . " -t " . $self->config('writer_device');

        system ("$command &");

        1;
}

1;
