# $Id: TitleTab.pm,v 1.23 2002/01/10 22:22:21 joern Exp $

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

sub clist_row2title_nr		{ shift->{clist_row2title_nr}		}	# href
sub set_clist_row2title_nr	{ shift->{clist_row2title_nr}	= $_[1] }

sub rip_title_widgets		{ shift->{rip_title_widgets}		}
sub set_rip_title_widgets	{ shift->{rip_title_widgets}	= $_[1] }


#------------------------------------------------------------------------
# Build RIP Title Tab
#------------------------------------------------------------------------

sub create_title_tab {
	my $self = shift; $self->trace_in;

	$self->set_rip_title_widgets({});

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
	$frame = Gtk::Frame->new ("DVD Table of Contents");
	$frame->show;
	$vbox->pack_start ( $frame, 0, 1, 0);

	$hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;
	$frame->add ( $hbox );

	my $list_vbox = Gtk::VBox->new;
	$list_vbox->show;
	$hbox->pack_start ( $list_vbox, 0, 1, 0);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	my $clist = Gtk::CList->new_with_titles (
		"Title", "Technical Information"
	);
	$clist->show,
	$clist->set_usize (400, 300);
	$clist->set_selection_mode( 'browse' ); 
	$clist->signal_connect ("select_row", sub { $self->cb_select_title (@_) } );

	$sw->add( $clist );

	$self->rip_title_widgets->{content_clist} = $clist;

	$list_vbox->pack_start ( $sw, 0, 1, 0);

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

	$self->rip_title_widgets->{audio_popup} = $audio_popup;

	$audio_vbox->pack_start($audio_popup, 0, 1, 0);

	# Viewing Angle Selection
	$label_hbox = Gtk::HBox->new;
	$label_hbox->show;
	$label = Gtk::Label->new ("Select Viewing Angle");
	$label->show;
	$label->set_justify('left');
	$label_hbox->pack_start ($label, 0, 1, 0);
	$audio_vbox->pack_start ($label_hbox, 0, 1, 0);
	
	my $view_angle_popup_menu = Gtk::Menu->new;
	$view_angle_popup_menu->show;
	$item = Gtk::MenuItem->new ("Angle 1");
	$item->show;
	$view_angle_popup_menu->append($item);
	my $view_angle_popup = Gtk::OptionMenu->new;
	$view_angle_popup->show;
	$view_angle_popup->set_menu($view_angle_popup_menu);

	$self->rip_title_widgets->{view_angle_popup} = $view_angle_popup;

	$audio_vbox->pack_start($view_angle_popup, 0, 1, 0);

	# Chapter mode ripping
	$label_hbox = Gtk::HBox->new;
	$label_hbox->show;
	$label = Gtk::Label->new ("Specify Chapter Mode");
	$label->show;
	$label_hbox->pack_start ($label, 0, 1, 0);
	$audio_vbox->pack_start ($label_hbox, 0, 1, 0);

	my $radio_hbox = Gtk::HBox->new;
	$radio_hbox->show;
	my $radio_no = Gtk::RadioButton->new ("No");
	$radio_no->show;
	$radio_hbox->pack_start($radio_no, 0, 1, 0);
	$audio_vbox->pack_start($radio_hbox, 0, 1, 0);
	my $radio_all = Gtk::RadioButton->new ("All", $radio_no);
	$radio_all->show;
	$radio_hbox->pack_start($radio_all, 0, 1, 0);
	my $radio_select = Gtk::RadioButton->new ("Selection", $radio_no);
	$radio_select->show;
	$radio_hbox->pack_start($radio_select, 0, 1, 0);

	$self->rip_title_widgets->{tc_use_chapter_mode_all}    = $radio_all;
	$self->rip_title_widgets->{tc_use_chapter_mode_no}     = $radio_no;
	$self->rip_title_widgets->{tc_use_chapter_mode_select} = $radio_select;

	# chapter selection list
	$sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->set_policy( 'automatic', 'automatic' );
	$sw->set_usize(undef, 156);

	my $chapter_clist = Gtk::CList->new_with_titles ( "Chapter Selection" );
	$sw->add( $chapter_clist );
	$chapter_clist->set_selection_mode( 'extended' );
	$chapter_clist->set_shadow_type( 'none' );
	$chapter_clist->show();

	$audio_vbox->pack_start($sw, 0, 1, 0);

	$self->rip_title_widgets->{chapter_select_window} = $sw;
	$self->rip_title_widgets->{chapter_select_clist}  = $chapter_clist;

	# 5. Show and RIP  Buttons
	$hbox = Gtk::HBox->new (1);
	$hbox->set_border_width(5);
	$hbox->show;
	$list_vbox->pack_start($hbox, 1, 1, 0);

	my $button;
	$button = Gtk::Button->new_with_label ("View Selected Title/Chapter(s)");
	$button->show;
	$hbox->pack_start ($button, 1, 1, 0);
	$button->signal_connect ("clicked",
		sub { $self->view_title }
	);

	$button = Gtk::Button->new_with_label (
		"RIP Selected Title/Chapter(s)"
	);
	$button->show;
	$button->signal_connect ("clicked",
		sub { $self->rip_title }
	);
	$hbox->pack_start ($button, 1, 1, 0);

	# 6. Fill Content List, if we have content
	$self->fill_content_list;

	$self->rip_title_widgets->{tc_use_chapter_mode_all}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_chapter_mode('all');
			$self->init_chapter_list ( without_radio => 1 );
		}
	);
	$self->rip_title_widgets->{tc_use_chapter_mode_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_chapter_mode(0);
			$self->init_chapter_list ( without_radio => 1 );
		}
	);
	$self->rip_title_widgets->{tc_use_chapter_mode_select}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_chapter_mode('select');
			$self->init_chapter_list ( without_radio => 1 );
		}
	);
	my $select_callback =  sub {
		my ($widget) = @_;
		my $title = $self->selected_title;
		return 1 if not $title;
		my @sel = $widget->selection;
		map { ++$_ } @sel;
		$title->set_tc_selected_chapters(\@sel);
		1;
	};
	$chapter_clist->signal_connect( "select_row", $select_callback );
	$chapter_clist->signal_connect( "unselect_row", $select_callback );

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

	my $audio_popup = $self->rip_title_widgets->{audio_popup};
	
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

	# viewing angle popup

	my $view_angle_popup = $self->rip_title_widgets->{view_angle_popup};
	
	my $view_angle_popup_menu = Gtk::Menu->new;
	$view_angle_popup_menu->show;
	$view_angle_popup->set_menu($view_angle_popup_menu);

	foreach my $angle ( 1 .. $title->viewing_angles ) {
		$item = Gtk::MenuItem->new ( "Angle $angle" );
		$item->show;
		$item->signal_connect (
			"select", sub {
				$_[1]->set_tc_viewing_angle($_[2]);
				$self->init_title_labels;
			},
			$title, $angle
		);
		$view_angle_popup_menu->append($item);
	}

	$view_angle_popup->set_history($title->tc_viewing_angle-1);

	1;
}

sub init_chapter_list {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($without_radio) = @par{'without_radio'};

	return if not $self->project->content->titles;
	my $title = $self->selected_title;
	return if not $title;

	my $widgets = $self->rip_title_widgets;
	my $chapter_mode = $title->tc_use_chapter_mode;

	if ( $chapter_mode eq 'select' ) {
		my $clist = $widgets->{chapter_select_clist};
		$clist->clear;
		$clist->freeze;
		my $chapters = $title->chapters;
		for (my $i=1; $i <= $chapters; ++$i ) {
			$clist->append ("Chapter $i");
		}
		my $selected_chapters = $title->tc_selected_chapters;
		foreach my $i ( @{$selected_chapters} ) {
			$clist->select_row($i-1, 0);
		}

		$widgets->{chapter_select_window}->show;
		$clist->thaw;
	} else {
		$widgets->{chapter_select_window}->hide;
	}

	# otherwise we end in a endless loop, because chapter-mode
	# callback calls ->init_title_labels
	return 1 if $without_radio;

	$widgets->{tc_use_chapter_mode_all}->set_active(1) if $chapter_mode eq 'all';
	$widgets->{tc_use_chapter_mode_no}->set_active(1)  if not $chapter_mode;
	$widgets->{tc_use_chapter_mode_select}->set_active(1) if $chapter_mode eq 'select';
	
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
			"Viewing Angle #".$title->tc_viewing_angle.", ".
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

	# good time creating the tmp dir (for the logfile);
	mkpath ( [ $self->project->snap_dir ], 0, 0755);

	my $project = $self->project;
	my $content = $project->content;

	$self->clear_content_list;

	# read TOC
	eval {
		$project->check_dvd_in_drive;
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
	
	my $titles = $content->get_titles_by_nr;
	my $step = -1;

	my $open_callback = sub {
		++$step;
		return $titles->[$step]->probe_async_start;
	};	

	my $progress_callback = sub {
		return $step+1;
	};

	my $close_callback = sub {
		my %par = @_;
		my ($progress, $output) = @par{'progress','output'};

		eval {
			$titles->[$step]->probe_async_stop (
				fh     => $progress->fh,
				output => $output
			);
			$titles->[$step]->suggest_transcode_options;
		};

		if ( not $@ ) {
			$self->append_content_list ( title => $titles->[$step] );
			$self->log ("Successfully probed title #".($step+1));

		} else {
			$self->message_window (
				message => "Can't probe Track #$step\n\n".
					   "Track will not be listed.\n\n".
					   "Output of tcprobe was:\n\n$output\n\n$@"
			);
			$self->log ("Error probing title #".($step+1));
		}
		
		++$step;

		if ( $step == @{$titles} ) {
			my $nr = $self->clist_row2title_nr->{0};
			$self->project->set_selected_title_nr ($nr);
			my $title = $self->project->content->titles->{$nr};
			$self->set_selected_title( $title );
			$self->fill_with_values;
			return 'finished';

		} else {
			$progress->init_pipe (
				fh => $titles->[$step]->probe_async_start
			);
			return 'continue';
		}
	};

	$self->comp('progress')->open (
		label             => "Reading DVD TOC",
		need_output       => 1,
		show_eta          => 1,
		show_percent      => 1,
		show_fps          => 0,
		max_value         => scalar(@{$titles}),
		open_callback     => $open_callback,
		progress_callback => $progress_callback,
		close_callback    => $close_callback,
	);

	1;
}

sub clear_content_list {
	my $self = shift; $self->trace_in;

	$self->rip_title_widgets->{content_clist}->clear;
	$self->set_clist_row2title_nr({});
	1;
}

sub fill_content_list {
	my $self = shift; $self->trace_in;
	
	return if not $self->project->content->titles;

	my $titles = $self->project->content->get_titles_by_nr;
	
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
	
	$self->rip_title_widgets
	     ->{content_clist}
	     ->select_row ($select_row, 1);

	1;
}

sub append_content_list {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($title) = @par{'title'};

	my $row = $self->rip_title_widgets->{content_clist}->append (
		$title->nr,
#		int($title->size/1024/1024),
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
	       $title->chapters." Chp, ".
	       "$fps fps, ".
	       $title->aspect_ratio.", ".
	       $title->frames." frames, ".
	       $title->width."x".$title->height.
	       ($title->tc_use_chapter_mode ? ", Chapter Mode" : "");
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

	eval { $self->project->check_dvd_in_drive };
	if ( $@ ) {
		$self->message_window (
			message => "Please put a disc into your drive."
		);
		return;
	}
	$self->project->check_dvd_in_drive;

	return $self->rip_title_chapters if $title->tc_use_chapter_mode;

	my $with_scanning = $title->audio_channel != -1;

	my $start_method = $with_scanning ? "rip_and_scan_async_start" :
					    "rip_async_start";
	my $stop_method  = $with_scanning ? "rip_and_scan_async_stop" :
					    "rip_async_stop";

	my $open_callback = sub {
		return $title->$start_method();
	};

	my $frames = 0;
	my $progress_callback = sub {
		# no progress bar for versions prior 0.6.0(pre)
		return 1 if $TC::VERSION < 600;

		# otherwise we get the output of "tcdemux -W" here,
		# where we just need to count lines (one frame per line)
		my %par = @_;
		my ($buffer) = @par{'buffer'};
		$frames += $buffer =~ tr/\n/\n/;
		return $frames;
	};

	my $close_callback = sub {
		my %par = @_;
		my ($progress, $output) = @par{'progress', 'output'};
		$title->$stop_method (
			fh     => $progress->fh,
			output => $output,
		);
		$title->suggest_transcode_options;
		$self->fill_with_values;
		return 'finished';
	};

	my $cancel_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};
		close ($progress->fh);
		$title->remove_vob_files;
		return 1;
	};

	$self->comp('progress')->open (
		label             => "Ripping Title #".$title->nr,
		need_output       => 1,
		show_percent      => ($TC::VERSION >= 600),
		show_eta          => ($TC::VERSION >= 600),
		show_fps          => ($TC::VERSION >= 600),
		max_value         => ($TC::VERSION >= 600 ? $title->frames : 1),
		open_callback     => $open_callback,
		progress_callback => $progress_callback,
		cancel_callback   => $cancel_callback,
		close_callback    => $close_callback,
	);

	1;
}

sub rip_title_chapters {
	my $self = shift; $self->trace_in;
	
	my $title = $self->selected_title;
	return if not $title;
	return if $self->comp('progress')->is_active;

	my $chapter_mode = $title->tc_use_chapter_mode;

	croak "Title is not in chapter mode" if not $chapter_mode;

	my $nr = $title->nr;

	my @chapters  = @{$title->get_chapters};
	my $max_value = $chapter_mode eq 'select' ?
				@chapters : 
				int ($title->size / 1024);

	if ( not @chapters ) {
		$self->message_window (
			message => "No chapters selected."
		);
		return;
	}

	my $cnt = 1;
	my $base_progress = 0;
	my $old_progress  = 0;

	my $chapter = shift @chapters;

	$title->set_actual_chapter ( $chapter );

	my $open_callback = sub {
		return $title->rip_async_start;
	};

	my $progress_callback = sub {
		return $cnt if $chapter_mode eq 'select';
		my %par = @_;
		my ($buffer) = @par{'buffer'};
		$buffer =~ /(\d+)-(\d+)\n[^\n]*$/s;
		my ($chunk, $bytes) = ($1, $2);
		my $progress = $base_progress + ($chunk-1)*1024*1024 + int($bytes/1024);
		$progress = $old_progress if $progress < $old_progress;
		$old_progress = $progress if $progress > 0;
		return $base_progress + ($chunk-1)*1024*1024 + int($bytes/1024);
	};

	my $close_callback = sub {
		my %par = @_;
		my ($progress, $output) = @par{'progress', 'output'};
		$title->rip_async_stop (
			fh     => $progress->fh,
			output => $output,
		);

		++$cnt;
		$chapter = shift @chapters;
		$title->set_actual_chapter($chapter);

		if ( not defined $chapter ) {
			$title->suggest_transcode_options;
			$self->fill_with_values;
			return 'finished';

		} else {
			$progress->set_label (
				"Ripping Chapter $chapter of Title #".$title->nr
			);
			$progress->init_pipe (
				fh => $title->rip_async_start
			);
			$base_progress = $old_progress;
			return 'continue';
		}
	};

	my $cancel_callback = sub {
		my %par = @_;
		my ($progress) = @par{'progress'};
		close ($progress->fh);
		$title->remove_vob_files;
		$title->set_actual_chapter(undef);
		return 1;
	};

	$self->comp('progress')->open (
		label             => "Ripping Chapter $chapter of Title #".$title->nr,
		need_output       => 0,
		show_percent      => ($chapter_mode ne 'select'),
		show_eta          => ($chapter_mode ne 'select'),
		show_fps          => 0,
		max_value         => $max_value,
		open_callback     => $open_callback,
		progress_callback => $progress_callback,
		cancel_callback   => $cancel_callback,
		close_callback    => $close_callback,
	);
	
	1;
}

sub view_title {
	my $self = shift;

	my $title = $self->selected_title;
	return if not $title;

	my $nr            = $title->nr;
	my $audio_channel = $title->audio_channel;
	
	my @mrls;
	if ( $title->tc_use_chapter_mode eq 'select' ) {
		my $chapters = $title->tc_selected_chapters;
		if ( not $chapters or not @{$chapters} ) {
			$self->message_window (
				message => "No chapters selected."
			);
			return;
		}
		foreach my $i ( @{$chapters} ) {
			push @mrls, "d4d://i".$nr."t0c".($i-1)."t".($i-1);
		}
	} else {
		push @mrls, "d4d://i".$nr."t0c0t0";
	}

	my $command =
		"xine ".
		join (" ", @mrls).
		" -a $audio_channel -p &";

	system ($command);
	
	1;
}

1;
