# $Id: TranscodeTabAudio.pm,v 1.5 2002/11/12 22:07:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

my $TABLE_SPACING = 5;

my %AUDIO_CODECS = (
	mp3    => { nr => 0, name => "MP3" 	},
	ogg    => { nr => 1, name => "Vorbis" 	},
	ac3    => { nr => 2, name => "AC3" 	},
	pcm    => { nr => 3, name => "PCM" 	},
	mp2    => { nr => 4, name => "MP2" 	},
);

sub create_audio_options {
	my $self = shift;

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	my $widgets = $self->transcode_widgets;

	# Frame
	$frame = Gtk::Frame->new ("Audio options");
	$frame->show;

	# Frame HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;
	$frame->add ($frame_hbox);

	# Frame VBox

	# Table
	$table = Gtk::Table->new ( 3, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );

	$frame_hbox->pack_start ($table, 1, 1, 0);

	# Select a DVD audio channel
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("DVD audio track");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$item = Gtk::MenuItem->new ("No Audio");
	$item->show;
	$popup_menu->append($item);
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_usize (200, undef);
	$popup->set_menu($popup_menu);

	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);
 
 	$widgets->{select_audio_channel_popup} = $popup;
 
 	++$row;
	$sep = new Gtk::HSeparator();
	$sep->show;
	$table->attach ($sep, 0, 2, $row, $row+1, 'fill','expand',0,0);
 
 	# Target audio channel
	++$row;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Target track");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);

	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_usize (200, undef);
	$popup->set_menu($popup_menu);

	%popup_entries = (
		'-' => "Don't add this track",
	);
	
	my $i = 0;
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		++$i;
	}

	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$popup->set_history(0);

 	$widgets->{tc_target_audio_channel_popup} = $popup;

	# Notebook for audio codec specific stuff
	$notebook = Gtk::Notebook->new;
	$notebook->set_tab_pos ('top');
	$notebook->set_homogeneous_tabs(1);
	$notebook->show;

	$widgets->{tc_audio_codec_notebook} = $notebook;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($notebook, 1, 1, 0);

	$frame_hbox->pack_start ($hbox, 1, 1, 0);
	
	my $hsize_group = Video::DVDRip::GUI::MinSizeGroup->new (
		type => 'h',
	);

	my $create_method;
	my %page2codec;
	foreach my $codec ( sort { $AUDIO_CODECS{$a}->{nr} <=>
				   $AUDIO_CODECS{$b}->{nr} }
			    keys   %AUDIO_CODECS ) {
		$label = Gtk::Label->new ($AUDIO_CODECS{$codec}->{name});
		$create_method = "create_audio_$codec"."_tab";
		$notebook->append_page (
			$self->$create_method ( hsize_group => $hsize_group ),
			$label
		);
		$page2codec{$AUDIO_CODECS{$codec}->{nr}} = $codec;
	}

	$notebook->signal_connect ("switch-page", sub {
		my ($nb, $page, $to_page) = @_;
		my $title = $self->selected_title;
		return 1 if not $title;
		return 1 if $self->in_transcode_init;
		$title->set_tc_audio_codec ( $page2codec{$to_page} );
		if ( $title->tc_audio_codec eq 'ogg' ) {
			$widgets->{view_avi_button}->child->set("View OGG");
			$widgets->{avisplit_button}->child->set("Split OGG");
		} else {
			$widgets->{view_avi_button}->child->set("View AVI");
			$widgets->{avisplit_button}->child->set("Split AVI");
		}
		$self->calc_video_bitrate;
		1;
	});

	return $frame;
}

sub create_audio_mp3_tab {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	# Tab HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;

	# Table
	$table = Gtk::Table->new ( 4, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Audio Bitrate
	$row = 0;
	$self->create_audio_bitrate (
		type  => "mp3",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	# Audio Filter
	++$row;
	$self->create_audio_filter (
		type  => "mp3",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);

	# Volume Rescale
	++$row;
	$self->create_audio_volume_rescale (
		type  => "mp3",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	# MP3 Quality
	++$row;
	$self->create_audio_mp3_quality (
		type  => "mp3",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	return $frame_hbox;
}

sub create_audio_ogg_tab {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	# Tab HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;

	# Table
	$table = Gtk::Table->new ( 3, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Audio Bitrate
	$row = 0;
	$self->create_audio_bitrate (
		type  => "ogg",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	# Audio Filter
	++$row;
	$self->create_audio_filter (
		type  => "ogg",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);

	# Volume Rescale
	++$row;
	$self->create_audio_volume_rescale (
		type  => "ogg",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	return $frame_hbox;
}

sub create_audio_ac3_tab {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	# Tab HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;

	# Table
	$table = Gtk::Table->new ( 3, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Audio Bitrate
	$row = 0;
	$self->create_audio_bitrate (
		type  => "ac3",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	$self->transcode_widgets->{tc_ac3_bitrate_combo}->set_sensitive ( 0 );

	# Passthrough note
	++$row;
	++$row;
	$label = Gtk::Label->new (
		"AC3 sound is passed through. The\n".
		"bitrate is detected from the source,\n".
		"so you can't change it here."
	);
	$label->show;
	$label->set_justify ("left");

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach_defaults ($hbox, 0, 2, $row, $row+1);

	return $frame_hbox;
}

sub create_audio_pcm_tab {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	# Tab HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;

	# Table
	$table = Gtk::Table->new ( 3, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Audio Bitrate
	$row = 0;
	$self->create_audio_bitrate (
		type  => "pcm",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	$self->transcode_widgets->{tc_pcm_bitrate_combo}->set_sensitive ( 0 );

	# Passthrough note
	++$row;
	++$row;
	$label = Gtk::Label->new (
		"PCM sound is passed through. The\n".
		"bitrate is detected from the source,\n".
		"so you can't change it here."
	);
	$label->show;
	$label->set_justify ("left");

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach_defaults ($hbox, 0, 2, $row, $row+1);

	return $frame_hbox;
}

sub create_audio_mp2_tab {
	my $self = shift;
	my %par = @_;
	my ($hsize_group) = @par{'hsize_group'};

	my ($frame, $frame_hbox, $table, $row, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	# Tab HBox
	$frame_hbox = Gtk::VBox->new;
	$frame_hbox->set_border_width(5);
	$frame_hbox->show;

	# Table
	$table = Gtk::Table->new ( 3, 2, 0 );
	$table->show;
	$table->set_row_spacings ( $TABLE_SPACING );
	$table->set_col_spacings ( $TABLE_SPACING );
	$frame_hbox->pack_start ($table, 0, 1, 0);

	# Audio Bitrate
	$row = 0;
	$self->create_audio_bitrate (
		type  => "mp2",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	# Audio Filter
	++$row;
	$self->create_audio_filter (
		type  => "mp2",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);

	# Volume Rescale
	++$row;
	$self->create_audio_volume_rescale (
		type  => "mp2",
		table => $table,
		row   => $row,
		hsize_group => $hsize_group
	);
	
	return $frame_hbox;
}

sub create_audio_bitrate {
	my $self = shift;
	my %par = @_;
	my  ($type, $table, $row, $hsize_group) =
	@par{'type','table','row','hsize_group'};

	my ($frame, $frame_hbox, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	my $widgets = $self->transcode_widgets;

	# Audio bitrate
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Audio bitrate");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedCombo->new (
		is_number	=> 1,
		is_min		=> 1,
	);
	$entry->show;
	$entry->set_popdown_strings (96, 128, 160, 192, 256, 320, 384);
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);

	$label = Gtk::Label->new ("kbit/s");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	my $attr = "tc_${type}_bitrate";
	my $method = "set_$attr";

	$widgets->{$attr} = $entry->entry;
	$widgets->{$attr."_combo"} = $entry;

	$entry->entry->signal_connect ("changed", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		return 1 if $self->in_transcode_init;
		$title->$method ($_[0]->get_text);
		$self->calc_video_bitrate;
		1;
	});

	1;
}

sub create_audio_filter {
	my $self = shift;
	my %par = @_;
	my  ($type, $table, $row, $hsize_group) =
	@par{'type','table','row','hsize_group'};

	my ($frame, $frame_hbox, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	my $widgets = $self->transcode_widgets;

	# Audio Filter
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Filter");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);
	$popup->set_usize (215,undef);

	my $i = 0;
	foreach my $key ( qw ( rescale a52drc normalize ) ) {
		$item = Gtk::MenuItem->new ($Video::DVDRip::audio_filters{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				shift;
				my ($k, $h) = @_;
				return 1 if $self->in_transcode_init;
				my $title = $self->selected_title;
				return 1 if not $title;
				$title->set_tc_audio_filter($k);
				foreach my $codec ( keys %AUDIO_CODECS ) {
					next if $type eq $codec;
					next if not exists
					    $widgets->{"audio_$codec"}
						    ->{tc_audio_filter_popup};
					$widgets->{"audio_$codec"}
						->{tc_audio_filter_popup}
						->set_history($h);
				}
				if ( $key eq 'normalize' ) {
					$title->set_tc_volume_rescale('');
					$self->transcode_widgets
					     ->{"audio_$type"}
					     ->{tc_volume_rescale}
					     ->set_text ('');
				} else {
					$title->set_tc_volume_rescale (
						$title->audio_tracks
						      ->[$title->audio_channel]
						      ->volume_rescale
					);
					$self->transcode_widgets
					     ->{"audio_$type"}
					     ->{tc_volume_rescale}
					     ->set_text ( $title->volume_rescale );
				}
			}, $key, $i
		);
		++$i;
	}

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($popup, 0, 1, 0);
	
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$widgets->{"audio_$type"}->{tc_audio_filter_popup} = $popup;
	
	1;
}

sub create_audio_volume_rescale {
	my $self = shift;
	my %par = @_;
	my  ($type, $table, $row, $hsize_group) =
	@par{'type','table','row','hsize_group'};

	my ($frame, $frame_hbox, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	my $widgets = $self->transcode_widgets;

	# Volume Rescale
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Volume rescale");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$entry = Video::DVDRip::CheckedEntry->new (undef,
		is_number	=> 1,
		may_fractional  => 1,
		may_empty	=> 1,
	);
	$entry->show;
	$entry->set_usize(80,undef);
	$hbox->pack_start($entry, 0, 1, 0);
	$table->attach_defaults ($hbox, 1, 2, $row, $row+1);

	$widgets->{"audio_$type"}->{tc_volume_rescale} = $entry;

	$entry->signal_connect ("focus-out-event", sub {
		my $title = $self->selected_title;
		return 1 if not $title;
		return 1 if $self->in_transcode_init;
		$title->set_tc_volume_rescale ($_[0]->get_text);
		foreach my $codec ( keys %AUDIO_CODECS ) {
			next if $type eq $codec;
			next if not exists $widgets->{"audio_$codec"}
						   ->{tc_volume_rescale};
			$self->set_in_transcode_init(1);
			$widgets->{"audio_$codec"}
				->{tc_volume_rescale}
				->set_text($_[0]->get_text);
			$self->set_in_transcode_init(0);
		}
		1;
	});

	$button = Gtk::Button->new (" Scan value ");
	$button->show;
	$hbox->pack_start($button, 0, 1, 0);

	$button->signal_connect ("clicked", sub { $self->scan_rescale_volume } );

	1;
}

sub create_audio_mp3_quality {
	my $self = shift;
	my %par = @_;
	my  ($type, $table, $row, $hsize_group) =
	@par{'type','table','row','hsize_group'};

	my ($frame, $frame_hbox, $hbox, $label, $entry, $vbox, $sep, $notebook);
	my ($popup_menu, $popup, $item, %popup_entries, $radio_yes, $radio_no, $button);

	my $widgets = $self->transcode_widgets;

	# MP3 Encoder Quality
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$label = Gtk::Label->new ("Quality");
	$label->show;
	$hbox->pack_start($label, 0, 1, 0);
	$table->attach ($hbox, 0, 1, $row, $row+1, 'fill','expand',0,0);
	$hsize_group->add ($hbox);

	$popup_menu = Gtk::Menu->new;
	$popup_menu->show;
	$popup = Gtk::OptionMenu->new;
	$popup->show;
	$popup->set_menu($popup_menu);

	%popup_entries = (
		0 => "0 - best but slower",
		1 => "1",
		2 => "2",
		3 => "3",
		4 => "4",
		5 => "5 - medium",
		6 => "6",
		7 => "7",
		8 => "8",
		9 => "9 - low but faster",
	);
	
	foreach my $key ( sort keys %popup_entries ) {
		$item = Gtk::MenuItem->new ($popup_entries{$key});
		$item->show;
		$popup_menu->append($item);
		$item->signal_connect (
			"activate", sub {
				return 1 if not $self->selected_title;
				return 1 if $self->in_transcode_init;
				$self->selected_title
				     ->set_tc_mp3_quality($key)
			}, $key
		);
	}

	$table->attach ($popup, 1, 2, $row, $row+1, 'fill','expand',0,0);

	$widgets->{tc_mp3_quality_popup} = $popup;

	return $frame_hbox;
}

sub init_audio_values {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($switch_popup, $dont_set_target_popup) =
	@par{'switch_popup','dont_set_target_popup'};

	my $title = $self->selected_title;
	return 1 if not $title;

	my $widgets = $self->transcode_widgets;
	return 1 if not defined $widgets->{tc_video_codec};

	return 1 if $title->audio_channel == -1;

	$self->set_in_transcode_init(1);

	$widgets->{tc_target_audio_channel_popup}->set_history (
		$title->tc_target_track + 1
	) if not $dont_set_target_popup;

	my $notebook = $widgets->{tc_audio_codec_notebook};

	my $audio_codec  = $title->tc_audio_codec;
	my $audio_filter = $title->tc_audio_filter;
	my $mp3_quality  = $title->tc_mp3_quality;

	$notebook->set_page( $AUDIO_CODECS{$audio_codec}->{nr} );

	$widgets->{tc_mp3_quality_popup}->set_history ($mp3_quality);

	my $audio_channel = $title->audio_channel;
	if ( $switch_popup ) {
		$switch_popup->set_history($audio_channel);
	} else {
		$self->rip_title_widgets->{audio_popup}->set_history($audio_channel);
		$self->transcode_widgets->{select_audio_channel_popup}->set_history($audio_channel);
	}

	my $ogg_show = "hide";
	my $mp3_show = "hide";
	my $ac3_show = "hide";
	my $mp2_show = "hide";
	my $pcm_show = "hide";

	$mp2_show = $title->tc_video_codec =~ /^S?VCD$/ ? "show" : "hide";

	if ( $title->ogg_container_possible ) {
		$ogg_show = "show";
	}

	if ( $title->avi_container_possible ) {
		$mp3_show = "show";

		if ( $title->audio_tracks->[$title->audio_channel]->ac3_ok ) {
			$ac3_show = "show";
			$title->tc_audio_tracks->[$title->audio_channel]->set_tc_ac3_bitrate(
				$title->audio_tracks->[$title->audio_channel]->bitrate
			);
		}
		if ( $title->audio_tracks->[$title->audio_channel]->pcm_ok ) {
			$pcm_show = "show";
			$title->tc_audio_tracks->[$title->audio_channel]->set_tc_pcm_bitrate(
				$title->audio_tracks->[$title->audio_channel]->bitrate
			);
		}
	}

	$pcm_show = "hide";	# doesn't work on my system

	my @pages = $widgets->{tc_audio_codec_notebook}->children;

	$pages[$AUDIO_CODECS{ac3}->{nr}]->child->$ac3_show();
	$pages[$AUDIO_CODECS{mp2}->{nr}]->child->$mp2_show();
	$pages[$AUDIO_CODECS{mp3}->{nr}]->child->$mp3_show();
	$pages[$AUDIO_CODECS{ogg}->{nr}]->child->$ogg_show();
	$pages[$AUDIO_CODECS{pcm}->{nr}]->child->$pcm_show();

	if ( $ogg_show eq 'show' and $mp3_show ne 'show' and
	     $audio_codec ne 'ogg' ) {
		# ogg is possible but mp3 not: so we should pre-select
		# the ogg codec page
		$notebook->set_page( $AUDIO_CODECS{ogg}->{nr} );
		$title->set_tc_audio_codec("ogg");
	}

	if ( $ogg_show ne 'show' and $mp3_show eq 'show' and
	     $audio_codec ne 'mp3' and $audio_codec ne 'ac3' ) {
		# mp3 is possible but ogg not: so we should pre-select
		# the mp3 codec page, if ogg is currently selected
		$notebook->set_page( $AUDIO_CODECS{mp3}->{nr} );
		$title->set_tc_audio_codec("mp3");
	}

	if ( $mp2_show eq 'show' and $audio_codec ne 'mp2' ) {
		# mp2 is posibble, so it should be pre-selected
		$notebook->set_page( $AUDIO_CODECS{mp2}->{nr} );
		$title->set_tc_audio_codec("mp2");
	}

	foreach my $codec ( keys %AUDIO_CODECS ) {
		next if not exists $widgets->{"audio_$codec"}
					   ->{tc_audio_filter_popup};
		$widgets->{"audio_$codec"}
			->{tc_audio_filter_popup}
			->set_history (
				$audio_filter eq 'rescale'   ? 0 :
				$audio_filter eq 'a52drc'    ? 1 :
				$audio_filter eq 'normalize' ? 2 : 0
			);
	}

	foreach my $codec ( keys %AUDIO_CODECS ) {
		next if not exists $widgets->{"audio_$codec"}
					   ->{tc_volume_rescale};
		$widgets->{"audio_$codec"}
			->{tc_volume_rescale}
			->set_text ( $title->tc_volume_rescale );
	}

	my $method;
	foreach my $codec ( keys %AUDIO_CODECS ) {
		my $method = "tc_$codec"."_bitrate";
		$widgets->{"tc_$codec"."_bitrate"}->set_text (
			$title->tc_audio_tracks
			      ->[$audio_channel]
			      ->$method
		);
	}

	if ( $title->tc_video_codec eq 'VCD' ) {
		$widgets->{tc_mp2_bitrate}->set_sensitive ( 0 );
	} else {
		$widgets->{tc_mp2_bitrate}->set_sensitive ( 1 );
	}

	$widgets->{tc_audio_codec_notebook}->set_sensitive (
		$title->tc_target_track != -1
	);

	$self->set_in_transcode_init(0);

	1;
}


1;
