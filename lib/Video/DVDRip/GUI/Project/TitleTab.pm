# $Id: TitleTab.pm,v 1.48 2002/11/03 11:35:16 joern Exp $

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

sub in_title_init		{ shift->{in_title_init}		}
sub set_in_title_init		{ shift->{in_title_init}	= $_[1]	}

#------------------------------------------------------------------------
# Build RIP Title Tab
#------------------------------------------------------------------------

sub create_title_tab {
	my $self = shift; $self->trace_in;

	$self->set_rip_title_widgets({});

	my $hsep;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	# 1. Read Content Button / Frame
	my $frame = Gtk::Frame->new ("Read content");
	$frame->show;

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	my $button = Gtk::Button->new_with_label ("Read DVD table of contents");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->read_dvd_toc } );

	$self->rip_title_widgets->{read_dvd_toc_button} = $button;

	my $label = Gtk::Label->new ("Press button, if list is empty or disc has changed.");
	$label->show;

	$hbox->pack_start ( $button, 0, 1, 0);
	$hbox->pack_start ( $label, 0, 1, 0);

	$frame->add ($hbox);
	$vbox->pack_start ( $frame, 0, 1, 0);

	# 2. TOC List / Frame
	$frame = Gtk::Frame->new ("DVD table of contents");
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
		"Title", "Technical information"
	);
	$clist->show,
	$clist->set_usize (450, 372);
	$clist->set_selection_mode( 'extended' ); 
	$clist->signal_connect ("select_row",   sub {
		return 1 if $self->in_title_init;
		$self->cb_select_title (@_);
	} );
	$clist->signal_connect ("unselect_row", sub {
		return 1 if $self->in_title_init;
		$self->cb_select_title (@_);
	} );

	$sw->add( $clist );

	$self->rip_title_widgets->{content_clist} = $clist;

	$list_vbox->pack_start ( $sw, 0, 1, 0);

	# 3. Audio Selection Popup
	my $audio_vbox = Gtk::VBox->new;
	$audio_vbox->show;
	$hbox->pack_start ($audio_vbox, 0, 1, 0);
	
	my $label_hbox = Gtk::HBox->new;
	$label_hbox->show;
	$label = Gtk::Label->new (
		"Select audio track for volume\n".
		"scanning.\n".
		"(Does not affect ripping, all\n".
		"audio tracks are ripped)"
	);
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

	$hsep = Gtk::HSeparator->new;
	$hsep->show;
	$audio_vbox->pack_start($hsep, 0, 1, 0);

	# Viewing Angle Selection
	$label_hbox = Gtk::HBox->new;
	$label_hbox->show;
	$label = Gtk::Label->new (
		"Select viewing angle\n".
		"(You must rip again if you\n".
		"change this)"
	);
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

	$hsep = Gtk::HSeparator->new;
	$hsep->show;
	$audio_vbox->pack_start($hsep, 0, 1, 0);

	# Chapter mode ripping
	$label_hbox = Gtk::HBox->new;
	$label_hbox->show;
	$label = Gtk::Label->new ("Specify chapter mode");
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
	$sw->set_usize(undef, 138);

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
	$button = Gtk::Button->new_with_label ("View\nselected title/chapter(s)");
	$button->show;
	$hbox->pack_start ($button, 1, 1, 0);
	$button->signal_connect ("clicked",
		sub { $self->view_title }
	);

	$self->rip_title_widgets->{view_title_button} = $button;

	$button = Gtk::Button->new_with_label (
		"RIP\nselected title(s)/chapter(s)"
	);
	$button->show;
	$button->signal_connect ("clicked",
		sub { $self->rip_title }
	);
	$hbox->pack_start ($button, 1, 1, 0);

	$self->rip_title_widgets->{rip_button} = $button;

	# 6. Fill Content List, if we have content
	$self->fill_content_list;

	$self->rip_title_widgets->{tc_use_chapter_mode_no}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_chapter_mode(0);
			$self->init_chapter_list ( without_radio => 1 );
			$self->rip_title_widgets->{rip_button}->set_sensitive(1);
			$self->rip_title_widgets->{rip_button}->set_sensitive(1);
			$self->set_render_vobsub_sensitive;
			1;
		}
	);
	$self->rip_title_widgets->{tc_use_chapter_mode_all}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_chapter_mode('all');
			$self->init_chapter_list ( without_radio => 1 );
			$self->rip_title_widgets->{rip_button}->set_sensitive(
				$self->project->rip_mode eq 'rip'
			);
			$self->set_render_vobsub_sensitive;
			1;
		}
	);
	$self->rip_title_widgets->{tc_use_chapter_mode_select}->signal_connect (
		"clicked", sub {
			return 1 if not $self->selected_title;
			$self->selected_title->set_tc_use_chapter_mode('select');
			$self->init_chapter_list ( without_radio => 1 );
			$self->rip_title_widgets->{rip_button}->set_sensitive(
				$self->project->rip_mode eq 'rip'
			);
			$self->set_render_vobsub_sensitive;
			1;
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

	my @sel = $clist->selection;
	if ( @sel > 1 ) {
		$self->rip_title_widgets->{view_title_button}->set_sensitive(0);
		return;
	}
	$self->rip_title_widgets->{view_title_button}->set_sensitive(1);
	$row = $sel[0];

	my $nr = $self->clist_row2title_nr->{$row};
	$self->project->set_selected_title_nr ($nr);
	my $title = $self->set_selected_title($self->project->content->titles->{$nr});

	$self->fill_with_values;
	
	my $rip_mode = $self->project->rip_mode;
	
	if ( $rip_mode eq 'rip' ) {
		$self->rip_title_widgets->{view_title_button}->set_sensitive(1);
		$self->rip_title_widgets->{rip_button}->set_sensitive(1);

	} elsif ( $rip_mode eq 'dvd' or $rip_mode eq 'dvd_image' ) {
		$self->rip_title_widgets->{view_title_button}->set_sensitive(
			$rip_mode eq 'dvd'
		);
		$self->rip_title_widgets->{rip_button}->set_sensitive(
			not $title->tc_use_chapter_mode
		) if $title;

	}
	
	1;
}

sub init_audio_popup {
	my $self = shift; $self->trace_in;

	return if not $self->project->content->titles;
	my $title = $self->selected_title;
	return if not $title;

	$self->fill_audio_popup (
		audio_popup => $self->rip_title_widgets->{audio_popup},
		tab         => "rip_title",
	);
	$self->fill_audio_popup (
		audio_popup => $self->transcode_widgets->{select_audio_channel_popup},
		tab         => "transcode",
	);
	$self->fill_target_audio_popup;

	# viewing angle popup

	my $view_angle_popup = $self->rip_title_widgets->{view_angle_popup};
	
	my $view_angle_popup_menu = Gtk::Menu->new;
	$view_angle_popup_menu->show;
	$view_angle_popup->set_menu($view_angle_popup_menu);

	my $item;
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

sub fill_audio_popup {
	my $self = shift;
	my %par = @_;
	my ($audio_popup, $tab) = @par{'audio_popup','tab'};

	$self->print_debug ("fill_audio_popup: entered for tab '$tab'");

	my $title = $self->selected_title;

	my $audio_popup_menu = Gtk::Menu->new;
	$audio_popup_menu->show;
	$audio_popup->remove_menu;
	$audio_popup->set_menu($audio_popup_menu);

	my $tc_audio_tracks = $title->tc_audio_tracks;

	my $item;
	my $i = 0;
	my @items;
	foreach my $audio ( @{$title->audio_tracks} ) {
		my $sample_rate = $audio->sample_rate;
		$sample_rate = "48kHz"   if $sample_rate == 48000;
		$sample_rate = "41.1kHz" if $sample_rate == 44100;

		my $target_track = "";
		if ( $tc_audio_tracks->[$i]->tc_target_track != -1 ) {
			$target_track = " => ".$tc_audio_tracks->[$i]->tc_target_track;
		} else {
			$target_track = " => skip";
		}
		
		$target_track = "" if $tab eq 'rip_title';
		
		$item = Gtk::MenuItem->new (
			"$i: ".$audio->lang." ".$audio->type." ".
			"$sample_rate ".$audio->channels."Ch".
			$target_track
		);

		$self->print_debug ("fill_audio_popup: New item: ".$item->child->get);

		$item->show;
		$item->signal_connect (
			"select", sub {
				return if $self->in_transcode_init;
				$_[1]->set_audio_channel($_[2]);
				$self->init_title_labels;
				$self->configure_target_audio_popup;
				if ( $tab eq 'rip_title' ) {
					$self->init_audio_values (
					    switch_popup =>
						$self->transcode_widgets
						     ->{select_audio_channel_popup}
					);
					$self->init_transcode_values (
						no_audio => 1
					);
				} else {
					$self->init_audio_values (
					    switch_popup =>
						$self->rip_title_widgets
						     ->{audio_popup}
					);
					$self->init_transcode_values (
						no_audio => 1
					);
				}
				1;
			},
			$title, $i
		);
		$audio_popup_menu->append($item);
		push @items, $item;
		++$i;
	}

	if ( $title->audio_channel == -1 ) {
		$item = Gtk::MenuItem->new ("No audio");
		$item->show;
		$audio_popup_menu->append($item);
		$audio_popup->set_history(0);
		
	} else {
		$audio_popup->set_history($title->audio_channel);
	}

	$self->transcode_widgets->{"items_$tab"} = \@items;

	1;
}

sub configure_target_audio_popup {
	my $self = shift;
	
	my $title = $self->selected_title;

	my $items = $self->rip_title_widgets->{target_popup_items};
	
	my %track_is_assigned;
	foreach my $audio ( @{$title->tc_audio_tracks} ) {
		$track_is_assigned{$audio->tc_target_track} = 1
			if $audio->tc_target_track != -1;
	}

	my $j = -1;
	foreach my $it ( @{$items} ) {
		$it->set_sensitive(
			!($track_is_assigned{$j} and 
			  $title->tc_target_track != $j)
		);
		++$j;
	}

	1;
}

sub fill_target_audio_popup {
	my $self = shift;

	my $title = $self->selected_title;

	my $audio_popup = $self->transcode_widgets->{tc_target_audio_channel_popup};

	my $audio_popup_menu = Gtk::Menu->new;
	$audio_popup_menu->show;
	$audio_popup->set_menu($audio_popup_menu);

	my %track_is_assigned;
	foreach my $audio ( @{$title->tc_audio_tracks} ) {
		$track_is_assigned{$audio->tc_target_track} = 1
			if $audio->tc_target_track != -1;
	}

	my @items;
	my $item;
	my $text;
	my %history;
	my $history = 0;
	for (my $i=-1; $i < @{$title->audio_tracks}; ++$i ) {
		$text = $i == -1 ? "Skip / Decativate this track" : "Track #$i";
		$history{$i} = $history;
		$item = Gtk::MenuItem->new ($text);
		push @items, $item;
		$item->show;
		$item->set_sensitive(0) if $track_is_assigned{$i} and
			$title->tc_target_track != $i;
		$item->signal_connect (
			"select", sub {
				return if $self->in_transcode_init;
				$title->set_tc_target_track ($_[1]);
				$title->calc_video_bitrate;
				$self->init_audio_values (
					dont_set_target_popup => 1
				);
				# this corrects the target track
				# in both popups
				$self->fill_audio_popup (
					audio_popup => $self->transcode_widgets
						 	    ->{select_audio_channel_popup},
					tab	    => "transcode"
				);
				$self->fill_audio_popup (
					audio_popup => $self->rip_title_widgets
						 	    ->{audio_popup},
					tab	    => "rip_title"
				);
				$self->calc_video_bitrate;
				1;
			},$i,
		);
		$audio_popup_menu->append($item);
		++$history;
	}

	$audio_popup->set_history ($history{$title->tc_target_track});
	$self->rip_title_widgets->{target_popup_items} = \@items;

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
			"Viewing angle #".$title->tc_viewing_angle.", ".
			"Audio track: #$audio_channel - ".
			$audio->lang." ".$audio->type." ".
			$audio->sample_rate." ".$audio->channels."Ch";
	} else {
		$audio_label = "No audio\n";
	}

	my $nr = $title->nr;

	foreach my $label ( @{$self->gtk_title_labels} ) {
		$label->set_text (
			"DVD title #$nr - ".
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

	my $nr;
	my $job;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new (
		reuse_progress => 1
	);
	
	foreach my $title ( @{$titles} ) {
		$job  = Video::DVDRip::Job::Probe->new (
			nr    => ++$nr,
			title => $title,
		);

		$job->set_progress_max(scalar(@{$titles})+0.001);

		$job->set_cb_finished (sub {
			$self->append_content_list ( title => $title );
		});

		$last_job = $exec->add_job ( job => $job );
	}
	
	$exec->set_cb_finished (sub{
		return if $exec->cancelled;

		my $nr = $self->clist_row2title_nr->{0};
		$self->project->set_selected_title_nr ($nr);

		my $title = $self->project->content->titles->{$nr};
		$self->set_selected_title( $title );
		$self->fill_with_values;
		$self->rip_title_widgets->{content_clist}->select_row (0,0);
		eval { $self->project->copy_ifo_files };
		if ( $@ ) {
			$self->long_message_window (
				message =>
					"Failed to copy the IFO files. vobsub creation ".
					"won't work properly.\nThe error message is:\n".
					$self->stripped_exception
					
			);
		}
		$self->project->backup_copy;

		1;
	});

	$exec->execute_jobs;

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

	if ( $self->project->rip_mode ne 'rip' ) {
		$self->rip_title_widgets->{rip_button}->set_sensitive(0);
	} else {
		$self->rip_title_widgets->{rip_button}->set_sensitive(1);
	}

	1;
}

sub append_content_list {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($title) = @par{'title'};

	my $row = $self->rip_title_widgets->{content_clist}->append (
		$title->nr,
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

	my $frame = Gtk::Frame->new ("Selected DVD title");
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

sub rip_title_selection_sensitive {
	my $self = shift;
	my ($value) = @_;

	my $widgets = $self->rip_title_widgets;
	
	$widgets->{content_clist}              -> set_sensitive($value);
	$widgets->{audio_popup}                -> set_sensitive($value);
	$widgets->{view_angle_popup}           -> set_sensitive($value);
	$widgets->{tc_use_chapter_mode_all}    -> set_sensitive($value);
	$widgets->{tc_use_chapter_mode_no}     -> set_sensitive($value);
	$widgets->{tc_use_chapter_mode_select} -> set_sensitive($value);
	$widgets->{chapter_select_clist}       -> set_sensitive($value);
	$widgets->{rip_button}                 -> set_sensitive($value);
	$widgets->{read_dvd_toc_button}        -> set_sensitive($value);

	1;
}

sub rip_title {
	my $self = shift; $self->trace_in;

	return if $self->comp('progress')->is_active;

	if ( not $self->selected_title ) {
		$self->message_window (
			message => "Please select at least one title."
		);
		return;
	}

	$self->rip_title_selection_sensitive(0);

	my $project = $self->comp('project')->project;

	eval { $self->project->check_dvd_in_drive };
	if ( $@ ) {
		$self->rip_title_selection_sensitive(1);
		$self->message_window (
			message => "Please put a disc into your drive. ($@)"
		);
		return;
	}

	my @sel = $self->rip_title_widgets->{content_clist}->selection;
	
	my $nr;
	my $job;
	my $last_job;
	my $exec = Video::DVDRip::GUI::ExecuteJobs->new;

	foreach my $sel ( @sel ) {
		my $title = $self->project->content->titles->{$sel+1};

		if ( not $title->tc_use_chapter_mode ) {
		    my $job = Video::DVDRip::Job::Rip->new (
			nr    => ++$nr,
			title => $title,
		    );
		    $last_job = $exec->add_job ( job => $job );

		} else {
		    foreach my $chapter ( @{$title->get_chapters} ) {
			$job = Video::DVDRip::Job::Rip->new (
			    nr    => ++$nr,
			    title => $title,
			);
			$job->set_chapter ( $chapter );
			$last_job = $exec->add_job ( job => $job );
		    }
		}
	}

	$exec->set_cb_finished (sub {
		if ( $exec->cancelled ) {
			$exec->cancelled_job->title->remove_vob_files
				if $exec->cancelled_job;
		} else {
			$self->grab_preview_frame;
			$self->fill_with_values;
			$self->project->backup_copy;
		}

		$self->rip_title_selection_sensitive(1);

		1;
	});

	$exec->execute_jobs (
		max_diskspace_needed => 6 * 1024
	);

	1;
}

sub view_title {
	my $self = shift;

	my $title = $self->selected_title;

	if ( not $title ) {
		$self->message_window (
			message => "Please select a title."
		);
		return;
	}

	if ( $title->tc_use_chapter_mode eq 'select' ) {
		my $chapters = $title->tc_selected_chapters;
		if ( not $chapters or not @{$chapters} ) {
			$self->message_window (
				message => "No chapters selected."
			);
			return;
		}
	}
	
	my $command = $title->get_view_dvd_command (
		command_tmpl => $self->config('play_dvd_command')
	);

	system ($command." &");
	
	1;
}

1;
