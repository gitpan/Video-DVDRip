# $Id: TitleTab.pm,v 1.10 2001/12/11 22:15:02 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

sub gtk_content_clist		{ shift->{gtk_content_clist}		}
sub set_gtk_content_clist	{ shift->{gtk_content_clist}	= $_[1] }

sub clist_row2title_nr		{ shift->{clist_row2title_nr}		}	# href
sub set_clist_row2title_nr	{ shift->{clist_row2title_nr}	= $_[1] }

sub gtk_audio_popup		{ shift->{gtk_audio_popup}		}	# lref
sub set_gtk_audio_popup		{ shift->{gtk_audio_popup}	= $_[1] }

sub gtk_tc_title_nr		{ shift->{gtk_tc_title_nr}		}
sub set_gtk_tc_title_nr		{ shift->{gtk_tc_title_nr}	= $_[1] }

#------------------------------------------------------------------------
# Build RIP Title Tab
#------------------------------------------------------------------------

sub create_title_tab {
	my $self = shift; $self->trace_in;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	# 1. Read Content Button / Frame
	my $frame = Gtk::Frame->new ("Read content");
	$frame->show;

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	my $button = Gtk::Button->new_with_label ("Read DVD Table of Contents");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->read_dvd_toc } );

	my $label = Gtk::Label->new ("Press button, if list is empty or disc has changed.");
	$label->show;

	$hbox->pack_start ( $button, 0, 1, 0);
	$hbox->pack_start ( $label, 0, 1, 0);

	$frame->add ($hbox);
	$vbox->pack_start ( $frame, 0, 1, 0);

	# 2. TOC List / Frame
	$frame = Gtk::Frame->new ("DVD Table of Contents (ordered by size)");
	$frame->show;
	$vbox->pack_start ( $frame, 0, 1, 0);

	$hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;
	$frame->add ( $hbox );

	my $list_vbox = Gtk::VBox->new;
	$list_vbox->show;
	$hbox->pack_start ( $list_vbox, 0, 1, 0);

	my $clist = Gtk::CList->new_with_titles (
		"Title", "Size (MB)", "Additional Information"
	);
	$clist->show,
	$clist->set_usize (400, 300);
	$clist->set_selection_mode( 'browse' ); 
	$clist->signal_connect ("select_row", sub { $self->cb_select_title (@_) } );
	$self->set_gtk_content_clist ($clist);
	
	$list_vbox->pack_start ( $clist, 0, 1, 0);

	# 3. Audio Selection Popup
	my $audio_vbox = Gtk::VBox->new;
	$audio_vbox->show;
	$hbox->pack_start ($audio_vbox, 0, 1, 0);
	
	my $label_hbox = Gtk::HBox->new;
	$label_hbox->show;
	$label = Gtk::Label->new ("Select Audio Channel");
	$label->show;
	$label->set_justify('left');
	$label_hbox->pack_start ($label, 0, 1, 0);
	$audio_vbox->pack_start ($label_hbox, 0, 1, 0);
	
	my $audio_popup_menu = Gtk::Menu->new;
	$audio_popup_menu->show;
	my $item = Gtk::MenuItem->new ("No Audio");
	$item->show;
	$audio_popup_menu->append($item);
	my $audio_popup = Gtk::OptionMenu->new;
	$audio_popup->show;
	$audio_popup->set_menu($audio_popup_menu);

	$self->set_gtk_audio_popup ($audio_popup);
	$audio_vbox->pack_start($audio_popup, 0, 1, 0);

	# 4. little help text
	$label = Gtk::Label->new (
		"\nFirst select the title you want\n".
		"to rip. The popup above shows you\n".
		"the audio channels available for\n".
		"this title. Both settings will be\n".
		"used for all subsequent steps.\n"
	);
	$label->show;
	$label->set_justify('left');
	$audio_vbox->pack_start ($label, 0, 1, 0);

	# 4a) transcode title mapping
	$label = Gtk::Label->new (
		"This is for hackers!\n".
		"Enter real transcode title number,\n".
		"if probing does not work\n".
		"(for the currently selected title)"
	);
	$label->show;
	$label->set_justify('left');
	$audio_vbox->pack_start ($label, 0, 0, 0);

	my $nr_hbox = Gtk::HBox->new;
	$nr_hbox->show;
	$audio_vbox->pack_start ($nr_hbox, 0, 1, 0);

	$label = Gtk::Label->new ("transcode title nr:");
	$label->show;
	$nr_hbox->pack_start ($label, 0, 1, 0);
	
	my $entry = Gtk::Entry->new;
	$entry->show;
	$entry->set_usize(60,undef);
	$nr_hbox->pack_start ($entry, 0, 1, 0);

	$entry->signal_connect ("changed", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		$title->set_tc_title_nr ($_[0]->get_text);
	} );

	$self->set_gtk_tc_title_nr ($entry);


	# 5. Show and RIP  Buttons
	$hbox = Gtk::HBox->new (1);
	$hbox->set_border_width(5);
	$hbox->show;
	$list_vbox->pack_start($hbox, 1, 1, 0);

	my $button;
	$button = Gtk::Button->new_with_label (" View Selected Title ");
	$button->show;
	$hbox->pack_start ($button, 1, 1, 0);
	$button->signal_connect ("clicked",
		sub { $self->view_title }
	);

	$button = Gtk::Button->new_with_label (
		"         RIP Selected Title         "
	);
	$button->show;
	$button->signal_connect ("clicked",
		sub { $self->rip_title }
	);
	$hbox->pack_start ($button, 1, 1, 0);

	# 6. Fill Content List, if we have content
	$self->fill_content_list;

	return $vbox;
}

sub cb_select_title {
	my $self = shift; $self->trace_in;
	my ($clist, $row, $column, $event) = @_;

	my $nr = $self->clist_row2title_nr->{$row};
	$self->project->set_selected_title_nr ($nr);
	$self->set_selected_title($self->project->content->titles->{$nr});
	
	$self->fill_with_values;
	
	1;
}

sub init_audio_popup {
	my $self = shift; $self->trace_in;

	return if not $self->project->content->titles;

	my $title = $self->selected_title;
	
	return if not $title;

	my $audio_popup = $self->gtk_audio_popup;
	
	my $audio_popup_menu = Gtk::Menu->new;
	$audio_popup_menu->show;
	$audio_popup->set_menu($audio_popup_menu);

	my $item = Gtk::MenuItem->new ("No Audio");
	$item->show;
	$item->signal_connect ("select", sub {
		$title->set_audio_channel(-1);
		$self->init_title_labels;
	} );
	$audio_popup_menu->append($item);

	my $i = 0;
	foreach my $audio ( @{$title->audio_tracks} ) {
		$item = Gtk::MenuItem->new (
			"$i: $audio->{lang} $audio->{type} ".
			"$audio->{sample_rate} $audio->{channels}Ch"
		);
		$item->show;
		$item->signal_connect (
			"select", sub {
				$_[1]->set_audio_channel($_[2]);
				$self->init_title_labels;
			},
			$title, $i
		);
		$audio_popup_menu->append($item);
		++$i;
	}

	$audio_popup->set_history($title->audio_channel+1);

	$self->gtk_tc_title_nr->set_text($title->tc_title_nr);

	1;
}

sub init_title_labels {
	my $self = shift; $self->trace_in;

	return if not $self->project->content->titles;
	
	my $title = $self->selected_title;

	return if not $title;

	my $audio_label;
	my $audio_channel = $title->audio_channel;
	if ( $audio_channel >= 0 ) {
		my $audio = $title->probe_result
			       ->audio_tracks
			       ->[$audio_channel];
		$audio_label =
			"Audio Channel: #$audio_channel - ".
			"$audio->{lang} $audio->{type} ".
			"$audio->{sample_rate} $audio->{channels}Ch";
	} else {
		$audio_label = "No Audio\n";
	}

	my $nr = $title->nr;

	foreach my $label ( @{$self->gtk_title_labels} ) {
		$label->set_text (
			"DVD Title #$nr - ".
			$self->get_title_info (title => $title).
			"\n".$audio_label
		);
	}

	1;
}

sub read_dvd_toc {
	my $self = shift; $self->trace_in;

	return if $self->comp('progress')->is_active;

	my $project = $self->project;
	my $content = $project->content;

	$self->clear_content_list;

	# read TOC
	eval {
		$content->read_title_listing;
	};
	if ( $@ ) {
		$self->message_window (
			message => "Can't read DVD TOC. Please put ".
				   "a disc into your drive.\n\n".
				   "Internal message was:\n".
				   $self->stripped_exception
		);
		return;
	}
	
	my $titles = $content->get_titles_by_size;

	$self->comp('progress')->open_steps_progress (
		title => "Read DVD TOC",
		steps => scalar(@{$titles}),
		label => "Probing Track #",
		need_output => 1,
		open_next_step_callback => sub {
			my %par = @_;
			my ($step) = @par{'step'};
			return $titles->[$step]->probe_async_start;
		},
		close_step_callback => sub {
			my %par = @_;
			my  ($step, $fh, $output) =
			@par{'step','fh','output'};
			eval {
				$titles->[$step]->probe_async_stop (
					fh     => $fh,
					output => $output
				);
				$titles->[$step]->suggest_transcode_options;
			};
			if ( not $@ ) {
				$self->append_content_list ( title => $titles->[$step] );
			} else {
				$self->message_window (
					message => "Can't probe Track #$step\n\n".
						   "Track will not be listed.\n\n".
						   "Output of tcprobe was:\n\n$output\n\n$@"
				);
			}
		},
		finished_callback => sub {
			my $nr = $self->clist_row2title_nr->{0};
			$self->project->set_selected_title_nr ($nr);
			my $title = $self->project->content->titles->{$nr};
			$self->set_selected_title( $title );
			$title->suggest_transcode_options;
			$self->fill_with_values;
			return;
		}
	);

	1;
}

sub clear_content_list {
	my $self = shift; $self->trace_in;

	$self->gtk_content_clist->clear;
	$self->set_clist_row2title_nr({});
	1;
}

sub fill_content_list {
	my $self = shift; $self->trace_in;
	
	return if not $self->project->content->titles;

	my $titles = $self->project->content->get_titles_by_size;
	
	$self->clear_content_list;
	
	my $row = 0;
	my $select_row;
	my $selected_title_nr = $self->project->selected_title_nr;

	foreach my $title ( @{$titles} ) {
		next if not defined $title->probe_result;
		$self->append_content_list ( title => $title );
		$select_row = $row if $selected_title_nr == $title->nr;
		++$row;
	}
	
	$self->gtk_content_clist->select_row ($select_row, 1);

	1;
}

sub append_content_list {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($title) = @par{'title'};

	my $row = $self->gtk_content_clist->append (
		$title->nr,
		int($title->size/1024/1024),
		$self->get_title_info ( title => $title ),
	);
	
	$self->clist_row2title_nr->{$row} = $title->nr;
}

sub get_title_info {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($title) = @par{'title'};
	
	my $fps = $title->frame_rate;
	$fps =~ s/\.0+$//;

	my $length = $title->runtime-1;
	my $h = int($length/3600);
	my $m = int(($length-$h*3600)/60);
	my $s = $length-$h*3600-$m*60;

	$length = sprintf ("%02d:%02d:%02d", $h, $m, $s);

	return $length.", ".
	       uc($title->video_mode).", ".
	       $title->width."x".$title->height.", ".
	       "$fps fps, ".
	       $title->aspect_ratio.", ".
	       $title->frames." frames";
}
		

sub create_selected_title {
	my $self = shift; $self->trace_in;

	my $frame = Gtk::Frame->new ("Selected Title");
	$frame->show;

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	my $label = Gtk::Label->new;
	$label->show;
	$label->set_justify('left');

	$hbox->pack_start ( $label, 0, 1, 0);

	$frame->add ($hbox);

	push @{$self->gtk_title_labels}, $label;

	return $frame;
}

sub rip_title {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return if not $title;
	return if $self->comp('progress')->is_active;

	my $with_scanning = $title->audio_channel != -1;

	my $start_method = $with_scanning ? "rip_and_scan_async_start" :
					    "rip_async_start";
	my $stop_method  = $with_scanning ? "rip_and_scan_async_stop" :
					    "rip_async_stop";
	my $window_title = $with_scanning ? "Rip and Scan DVD Title" :
					    "Rip DVD Title";

	my $fh = $title->$start_method();
	my $max_value = int ($title->size / 1024);

	$self->comp('progress')->open_continious_progress (
		max_value => $max_value,
		label     => "Ripping Track",
		fh        => $fh,
		need_output => 1,
		get_progress_callback => sub {
			my %par = @_;
			my ($buffer) = @par{'buffer'};
			$buffer =~ /(\d+)-(\d+)\n[^\n]*$/s;
			my ($chunk, $bytes) = ($1, $2);
			my $progress = ($chunk-1)*1024*1024 + int($bytes/1024);
			$progress = $max_value if not $chunk;
			return $progress;
		},
		finished_callback => sub {
			my %par = @_;
			my ($output) = @par{'output'};
			$title->$stop_method (
				fh => $fh,
				output => $output,
			);
			$title->suggest_transcode_options;
			$self->fill_with_values;
			return;
		},
		cancel_callback => sub {
			close $fh;
			$title->remove_vob_files;
		},
	);
	
	1;
}

sub view_title {
	my $self = shift;

	my $title = $self->selected_title;
	return if not $title;

	my $nr            = $title->nr;
	my $audio_channel = $title->audio_channel;
	
	my $command = "xine d4d://i".$nr."t0c0t0 -a $audio_channel -p &";
#	$command = "gmplayer -dvd $nr -aid $audio_channel &";

	system ($command);
	
	1;
}

1;
