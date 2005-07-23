# $Id: Transcode.pm,v 1.3 2005/07/23 10:05:25 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Transcode;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	$self->get_context->set_object ( "transcode" => $self );

	return $self;
}

sub build_factory {
	my $self = shift;

	my $context = $self->get_context;

	return Gtk2::Ex::FormFactory::VBox->new (
	    title 	=> __"Transcode",
	    object	=> "title",
	    no_frame    => 1,
	    content 	=> [
	        Video::DVDRip::GUI::Main->build_selected_title_factory,
		Gtk2::Ex::FormFactory::Table->new (
		    expand => 1,
		    layout => "
+>>>>>>>>>>>>>>>>>>>>>+>>>>>>>>>>>>>>>>>>>>>+
| Video & Bitrate     | Audio & General     |
+---------------------+---------------------|
^ Calculated Storage  | Operate             |
+---------------------+---------------------+
",
		    content => [
		        Gtk2::Ex::FormFactory::VBox->new (
			    content => [
			        $self->build_container_factory,
				$self->build_video_factory,
				$self->build_video_bitrate_factory,
			    ],
			),
		        Gtk2::Ex::FormFactory::VBox->new (
			    content => [
				$self->build_audio_factory,
				$self->build_general_options_factory,
			    ],
			),
			$self->build_calc_storage_factory,
			$self->build_operate_factory,
		    ],
		),
	    ],
	);
}

sub build_container_factory {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::Form->new (
	    title => __"Container options",
	    content => [
	        Gtk2::Ex::FormFactory::Popup->new (
		    label => __"Select container",
		    label_group => "video_labels",
		    attr  => "title.tc_container",
		    expand_h => 0,
		    width => 70,
		),
	    ],
	);
}

sub build_video_factory {
	my $self = shift;

	return Gtk2::Ex::FormFactory::Table->new (
	    title => __"Video options",
	    properties => {
	      column_spacing => 5,
	    },
	    layout => "
+>------------+[>--------------+[>--------------------+
| Codec Label | VC Popup       | Cfg Button           |
+-------------+[---------------+--------------+-------+
| ffmpeg Label| ffmpeg Entry   | KFI Label    | KFI   |
+-------------+[---------------+--------------+-------+
| FRate Label | Frame-Rate     |                      |
+-------------+[---------------+----------------------+
| 2pass Label | 2pass Yes/No   | Reuse log            | 
+-------------+----------------+----------------------+
| Deint Label | Deinterlacing                         |
+-------------+---------------------------------------+
| Filt Label  | Filters Button                        |
+-------------+---------------------------------------+
",
	    content => [
	    	#-- 1st row
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"Video codec",
		    label_group => "video_labels",
		),
	        Gtk2::Ex::FormFactory::Combo->new (
		    attr  => "title.tc_video_codec",
		    width => 70,
		    tip   => __"Choose a video codec here. If you don't ".
			       "find the codec you want in the list, just ".
			       "enter its transcode name by hand",
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    attr  => "title.video_codec_details",
		    label => __"Configure...",
		    stock => "gtk-preferences",
		    tip   => __"The xvid4 video codec may be configured in detail ".
		    	       "if you have the xvid4conf utility installed",
		    clicked_hook => sub {
		        $self->open_video_configure_window;
		    },
		),

		#-- 2nd row
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"ffmpeg/af6 codec",
		    for   => "sibling(1)"
		),
	        Gtk2::Ex::FormFactory::Entry->new (
		    attr  => "title.tc_video_af6_codec",
		    width => 70,
		    tip   => __"Some transcode video export modules support ".
		    	       "multiple video codecs, e.g. the ffmpeg module. ".
			       "Enter the name of the video codec the module ".
			       "should use here"
		),
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"Keyframes",
		),
	        Gtk2::Ex::FormFactory::Combo->new (
		    attr  => "title.tc_keyframe_interval",
		    width => 50,
		    tip   => __"This setting controls the number of frames ".
		    	       "after which a keyframe should be inserted ".
			       "into the video stream. The lower this value ".
			       "the better the quality, but filesize may ".
			       "increase as well",
		    rules => [ "positive-integer" ],
		),

	    	#-- 3rd row
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"Video framerate",
		),
	        Gtk2::Ex::FormFactory::Combo->new (
		    attr  => "title.tc_video_framerate",
		    width => 70,
		    tip   => __"This is the video framerate of this movie. ".
		    	       "Only change this if transcode detected the ".
			       "framerate wrong, which may happen sometimes. ".
			       "If you want true framerate conversion check ".
			       "out the Filters dialog, which provides some ".
			       "video filters for this task",
		    rules => [ "positive-float" ],
		),
		
		#-- 4th row
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"2-pass encoding",
		),
	        Gtk2::Ex::FormFactory::YesNo->new (
		    attr => "title.tc_multipass",
		    tip  => __"2-pass encoding increases video quality and ".
		    	      "video bitrate accuracy significantly. But the ".
			      "whole transcoding needs nearly twice the time. ".
			      "It's strongly recommended to use 2-pass encoding ".
			      "whenever possible."
		),
	        Gtk2::Ex::FormFactory::CheckButton->new (
		    label => __"Reuse log",
		    attr  => "title.tc_multipass_reuse_log",
		    tip   => __"During the first pass of a 2-pass transcoding ".
		    	       "a logfile with statistic information about the ".
			       "movie is written. If you didn't change any ".
			       "parameters affecting the video you may reuse ".
			       "this logfile for subsequent transcodings ".
			       "by activating this button. dvd::rip ".
			       "will skip the first pass saving much time."
		),

		#-- 5th row
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"Deinterlace mode",
		),
	        Gtk2::Ex::FormFactory::Popup->new (
		    attr => "title.tc_deinterlace",
		    expand_h => 0,
		    width => 160,
		    tip  => __"Choose a deinterlacer algorithm here if the ".
		    	      "movie is interlaced, otherwise the transcoded ".
			      "movie is likely to have many artefacts. The ".
			      "'Smart deinterlacing' setting is recommended."
		),

		#-- 5th row
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"Filters",
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label => __"Configure filters & preview...",
		    tip   => __"This opens a dialog which gives you access ".
		    	       "all filters transcode supports.",
		    active => 0,
		),

	    ],
	);
}

sub build_audio_factory {
	my $self = shift;

	return Gtk2::Ex::FormFactory::Table->new (
	    title => __"Audio options",
	    layout => "
+-----------+>------------+-------+
| DVD Track | Popup       | Multi |
+---------------------------------+
| Settings Notebook               |
|                                 |
+---------------------------------+
",
	    content => [
	        Gtk2::Ex::FormFactory::Label->new (
		    label => __"Select track",
		),
	        Gtk2::Ex::FormFactory::Popup->new (
		    attr  => "title.audio_channel",
		    width => 120
		),
	        Gtk2::Ex::FormFactory::Button->new (
		    label => __"Multi...",
		    stock => "dvdrip-audio-matrix",
		    clicked_hook => sub {
		        $self->open_multi_audio_window;
		    },
		    tip => __"Manage multiple audio tracks"
		),
		Gtk2::Ex::FormFactory::Notebook->new (
		    attr    => "audio_track.tc_audio_codec",
		    content => [
		        $self->build_audio_codec_settings ( type => "mp3" ),
		        $self->build_audio_codec_settings ( type => "mp2" ),
		        $self->build_audio_codec_settings ( type => "vorbis" ),
		        $self->build_audio_codec_settings ( type => "ac3" ),
		        $self->build_audio_codec_settings ( type => "pcm" ),
		    ],
		),
	    ],
	);
}

sub build_audio_codec_settings {
	my $self = shift;
	my %par = @_;
	my ($type) = @par{'type'};

	my ($title, @additional_widgets);
	
	my $bitrate_entry_class    = "Gtk2::Ex::FormFactory::Combo";
	my $samplerate_entry_class = "Gtk2::Ex::FormFactory::Combo";
	my $bitrate_attr           = "tc_${type}_bitrate";
	my $samplerate_attr        = "tc_${type}_samplerate";

	if ( $type eq 'mp3' ) {
		$title = "MP3";
		push @additional_widgets, Gtk2::Ex::FormFactory::Popup->new (
		    attr  => "audio_track.tc_mp3_quality",
		    label => __"Quality",
		),
	} elsif ( $type eq 'mp2' ) {
		$title = "MP2";
		$samplerate_entry_class = "Gtk2::Ex::FormFactory::Entry";

	} elsif ( $type eq 'vorbis' ) {
		$title = "Vorbis";
		push @additional_widgets, Gtk2::Ex::FormFactory::HBox->new (
		    label     => __"Quality",
		    label_for => "tc_vorbis_quality",
		    content => [
		        Gtk2::Ex::FormFactory::Combo->new (
			    name  => "tc_vorbis_quality",
			    attr  => "audio_track.tc_vorbis_quality",
			    width => 70,
			    rules => [ "positive-integer" ],
			),
		        Gtk2::Ex::FormFactory::CheckButton->new (
			    attr  => "audio_track.tc_vorbis_quality_enable",
			    label => __"Use quality mode",
			),
		    ],
		),
	} else {
		my $codec = $type eq 'ac3' ? "AC3" : "PCM";
		$title = $codec;
		push @additional_widgets, Gtk2::Ex::FormFactory::Label->new (
		    label => __x(
		    	"{ac3_or_pcm} sound is passed through. Bit- and\n".
			"samplerate are detected from source,\n".
			"so you can't change them here.",
			ac3_or_pcm => $codec
		    ),
		);
		$bitrate_entry_class    = "Gtk2::Ex::FormFactory::Entry";
		$samplerate_entry_class = "Gtk2::Ex::FormFactory::Entry";
		$bitrate_attr           = "bitrate";
		$samplerate_attr        = "sample_rate";
	}
	
	if ( $type ne 'ac3' and $type ne 'pcm' ) {
		push @additional_widgets, (
		    Gtk2::Ex::FormFactory::Popup->new (
		    	attr  => "audio_track.tc_audio_filter",
			label => __"Filter",
		    ),
	            Gtk2::Ex::FormFactory::HBox->new (
			label => __"Volume rescale",
			content => [
	        	    Gtk2::Ex::FormFactory::Entry->new (
			    	attr  => "audio_track.tc_volume_rescale",
				width => 70,
				rules => [ "positive-float", "or-empty" ],
			    ),
			    Gtk2::Ex::FormFactory::Button->new (
				label => __"Scan value",
				stock => "dvdrip-scan-volume",
				clicked_hook => sub {
				    $self->scan_rescale_volume;
				},
			    ),
			],
		    ),
		),
	}
	
	return Gtk2::Ex::FormFactory::Form->new (
	    attr    => "audio_track.audio_codec_${type}_form",
	    inactive => "invisible",
	    title   => $title,
	    content => [
	        Gtk2::Ex::FormFactory::HBox->new (
		    label     => __"Bit-/Samplerate",
		    content   => [
		        $bitrate_entry_class->new (
			    name  => "bit_samplerate_$type",
			    attr  => "audio_track.$bitrate_attr",
			    width => 70,
			    rules => [ "positive-integer" ],
			),
			Gtk2::Ex::FormFactory::Label->new (
			    label => __"kbit/s",
			    for   => "bit_samplerate_$type",
			),
	        	$samplerate_entry_class->new (
			    name  => $type.$samplerate_attr,
			    attr  => "audio_track.$samplerate_attr",
			    width => 70,
			    rules => [ "positive-integer" ],
			),
			Gtk2::Ex::FormFactory::Label->new (
			    label => __"hz",
			    for   => $type.$samplerate_attr,
			),
		    ],
		),
		@additional_widgets,
	    ],
	);
}

sub build_video_bitrate_factory {
	my $self = shift;
	
	my $context = $self->get_context;
	
	return Gtk2::Ex::FormFactory::Notebook->new (
	    attr    => "title.tc_video_bitrate_mode",
	    title   => __"Video bitrate calculation",
	    expand  => 1,
	    content => [
	        Gtk2::Ex::FormFactory::Form->new (
		    title   => __"By target size",
		    content => [
		        Gtk2::Ex::FormFactory::HBox->new (
			    label       => __"Target media",
			    label_group => "vbr_calc_group",
			    content => [
			        Gtk2::Ex::FormFactory::Popup->new (
				    attr => "title.tc_disc_cnt",
				    width => 70,
				    tip   => __"Choose the desired number of discs here. ".
				    	       "dvd::rip computes the target size from it ".
					       "and optionally splits the result file accordingly.",
				),
				Gtk2::Ex::FormFactory::Label->new (
				    label => "x",
				),
				Gtk2::Ex::FormFactory::Combo->new (
				    width => 60,
				    attr => "title.tc_disc_size",
				    tip   => __"Select the size of your media here (several ".
				    	       "CD and DVD form factors). The unit is a true ".
					       "megabyte (1024KB). You may enter an arbitrary ".
					       "value if the preset don't fit your needs.",
				    rules => [ "positive-integer", "not-zero" ],
				),
				Gtk2::Ex::FormFactory::Label->new (
				    label => __"MB",
				),
			    ],
			),
		        Gtk2::Ex::FormFactory::HBox->new (
			    label       => __"Target size",
			    label_group => "vbr_calc_group",
			    content => [
				Gtk2::Ex::FormFactory::Entry->new (
				    attr => "title.tc_target_size",
				    width => 50,
				    tip   => __"This entry is computed based on the settings above, ".
				    	       "but you may enter an arbitrary value as well.",
				    rules => [ "positive-integer", "not-zero" ],
				),
				Gtk2::Ex::FormFactory::Label->new (
				    label => __"MB",
				),
				Gtk2::Ex::FormFactory::CheckButton->new (
				    attr  => "title.tc_video_bitrate_range",
				    label => __"Consider frame range",
				    tip   => __"If you specified a frame range in the 'General options' ".
				    	       "section activate this checkbutton if the video bitrate ".
					       "calculation should be based on this frame range, and not on ".
					       "the full title length. You need this if you entered the frame ".
					       "range not just for testing purposes but also for the final ".
					       "transcoding, e.g. for cutting off credits."
				),
			    ],
			),
		    ],
		),
	        Gtk2::Ex::FormFactory::Form->new (
		    title   => __"By quality",
		    content => [
		        Gtk2::Ex::FormFactory::Combo->new (
			    attr	=> "title.tc_video_bpp_manual",
			    label       => __"BPP value",
			    label_group => "vbr_calc_group",
			    width       => 80,
			    expand_h    => 0,
			    tip         => __"BPP stands for Bits Per Pixel and is a measure for ".
			    		     "the video quality. Values around 0.25 give fair results ".
					     "(VHS quality), 0.4-0.5 very good quality near DVD.",
			    rules       => [ "positive-float", "not-zero" ],
			),
		    ],
		),
	        Gtk2::Ex::FormFactory::Form->new (
		    title => __"Manually",
		    content => [
		        Gtk2::Ex::FormFactory::HBox->new (
			    label       => __"Video bitrate",
			    label_group => "vbr_calc_group",
			    content => [
		        	Gtk2::Ex::FormFactory::Entry->new (
				    attr	=> "title.tc_video_bitrate_manual",
				    width       => 60,
				    expand_h    => 0,
				    tip         => __"If you don't want a calculated video bitrate ".
				    		     "just enter an arbitrary value here.",
				    rules       => [ "positive-integer", "not-zero" ],
				),
		        	Gtk2::Ex::FormFactory::Label->new (
				    label => __"kbit/s",
				),
			    ],
			),
		    ],
		),
	    ],
	);
}

sub build_general_options_factory {
	my $self = shift;
	
	my $context = $self->get_context;

	return Gtk2::Ex::FormFactory::Form->new (
	    title => __"General options",
	    content => [
	        Gtk2::Ex::FormFactory::HBox->new (
		    label => __"Frame range",
		    content => [
		        Gtk2::Ex::FormFactory::Entry->new (
			    attr  => "title.tc_start_frame",
			    width => 60,
			    rules => [
			    	"positive-integer", "or-empty",
				sub {
				    my ($start) = @_;
				    my $title = $self->selected_title;
				    my $end = $title->tc_end_frame;
				    return __x("Movie has only {number} frames", number => $title->frames)
				    	if $start > $title->frames;
				    $end ne '' && $start >= $end
				    ? __"Start frame number must be smaller than end frame number" : "";
				},
			    ],
			),
		        Gtk2::Ex::FormFactory::Label->new (
			    label => " - ",
			),
		        Gtk2::Ex::FormFactory::Entry->new (
			    attr  => "title.tc_end_frame",
			    width => 60,
			    rules => [
			    	"positive-integer", "or-empty",
				sub {
				    my ($end) = @_;
				    my $title = $self->selected_title;
				    my $start = $title->tc_start_frame;
				    return __x("Movie has only {number} frames", number => $title->frames)
				    	if $end > $title->frames;
				    $start ne '' && $start >= $end
				    ? __"End frame number must be greated than start frame number" : "";
				},
			    ],
			),
		    ],
		),
		Gtk2::Ex::FormFactory::Entry->new (
		    attr  => "title.tc_options",
		    label => __"transcode options",
		    width => 20,
		),
		Gtk2::Ex::FormFactory::Combo->new (
		    attr  => "title.tc_nice",
		    label => __"Process nice level",
		    width => 60,
		    expand_h => 0,
		    rules => [ "integer", "or-empty" ],
		),
		Gtk2::Ex::FormFactory::YesNo->new (
		    attr  => "title.tc_preview",
		    label => __"Preview window",
		),
		Gtk2::Ex::FormFactory::YesNo->new (
		    attr  => "title.tc_psu_core",
		    label => __"Use PSU core",
		),
	        Gtk2::Ex::FormFactory::HBox->new (
		    label => __"Execute afterwards",
		    content => [
		        Gtk2::Ex::FormFactory::Entry->new (
			    attr   => "title.tc_execute_afterwards",
			    expand => 1,
			    width  => 20,
			),
		        Gtk2::Ex::FormFactory::CheckButton->new (
			    attr   => "title.tc_exit_afterwards",
			    label => __"and exit",
			),
		    ],
		),
	    ],
	);
}

sub build_operate_factory {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::VBox->new (
	    title => __"Operate",
	    content => [
		Gtk2::Ex::FormFactory::HBox->new (
		    content => [
	        	Gtk2::Ex::FormFactory::Button->new (
			    label => __"Transcode",
			    stock => "gtk-convert",
			    widget_group => "operate_buttons",
			    expand => 1,
			    clicked_hook => sub {
			        $self->transcode,
			    },
			),
	        	Gtk2::Ex::FormFactory::Button->new (
			    label => __"View",
			    stock => "gtk-media-play",
			    widget_group => "operate_buttons",
			    expand => 1,
			    clicked_hook => sub {
			        $self->view_avi,
			    },
			),
	        	Gtk2::Ex::FormFactory::Button->new (
			    label => __"Add to cluster",
			    stock => "gtk-network",
			    widget_group => "operate_buttons",
			    expand => 1,
			    clicked_hook => sub {
			        $self->add_to_cluster;
			    },
			),
		    ],
		),
		Gtk2::Ex::FormFactory::CheckButton->new (
		    attr  => "title.tc_split",
		    label => __"Split files on transcoding",
		),

	    ],
	);
}

sub build_calc_storage_factory {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::Table->new (
	    title   => __"Calculated storage",
	    layout  => "
+>---------------+>--------]+>--+>---------------+>---------]+-----+
| V-Rate         | Value    | X | Video Size     |     Value | MB  |
+----------------+---------]+---+----------------+----------]+-----+
| BPP            | Value    |   | Audio Size     |     Value | MB  |
+----------------+----------+---+----------------+----------]+-----+
|                           |   | Other Size     |     Value | MB  |
+[---------------+----------+---+----------------+-----------+-----+
|                           |   | Separator                        |
|                           +---+----------------+----------]+-----+
_ Details                   |   | Total Size     |     Value | MB  |
+----------------+----------+---+----------------+-----------+-----+
",
	    content => [
	    	#-- 1st row
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"V-Rate:",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    attr  => "title.tc_video_bitrate",
		),
		Gtk2::Ex::FormFactory::Label->new ( label => "    " ),
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"Video size:",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    attr => "title.storage_video_size",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"MB",
		),
#		Gtk2::Ex::FormFactory::Label->new ( label => " " ),

		#-- 2nd row
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"BPP:",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    attr  => "title.tc_video_bpp",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"Audio size:",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    attr => "title.storage_audio_size",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"MB",
		),

		#-- 3rd row
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"Other size:",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    attr => "title.storage_other_size",
		),
		Gtk2::Ex::FormFactory::Label->new (
		    label => __"MB",
		),
		
		#-- 4th row
		Gtk2::Ex::FormFactory::Button->new (
		    label => __"Details...",
		    stock => "gtk-justify-left",
		    clicked_hook => sub {
		        $self->open_bitrate_calc_details;
		    },
		),
		Gtk2::Ex::FormFactory::HSeparator->new,
		
		#-- 5th row
		Gtk2::Ex::FormFactory::Label->new (
		    label => "<b>".__("Total size:")."</b>",
		    with_markup => 1,
		),
		Gtk2::Ex::FormFactory::Label->new (
		    attr => "title.storage_total_size",
		    bold => 1,
		),
		Gtk2::Ex::FormFactory::Label->new (
		    label => "<b>".__("MB")."</b>",
		    with_markup => 1,
		),
	    ],
	);
}

sub open_bitrate_calc_details {
	my $self = shift;
	
	require Video::DVDRip::GUI::BitrateCalc;
	
	my $bc = Video::DVDRip::GUI::BitrateCalc->new (
		form_factory => $self->get_form_factory
	);
	
	$bc->open_window;
	
	1;
	
}

sub open_multi_audio_window {
	my $self = shift;
	
	require Video::DVDRip::GUI::MultiAudio;
	
	my $maudio = Video::DVDRip::GUI::MultiAudio->new (
		form_factory => $self->get_form_factory
	);
	
	$maudio->open_window;
	
	1;
}

sub transcode {
	my $self = shift;
	my %par = @_;
	my ($subtitle_test) = @par{'subtitle_test'};

	return 1 if $self->progress_is_active;

	my $title = $self->selected_title;

	return 1 if not $title;

	Video::DVDRip::InfoFile->new (
		title    => $title,
		filename => $title->info_file,
	)->write;

	my $mpeg     = $title->tc_video_codec =~ /^(X?S?VCD|CVD)$/;
	my $split    = $title->tc_split;
	my $chapters = $title->get_chapters;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => __"You first have to rip this title."
		);
		return 1;
	}

	if ( $title->tc_psu_core and
	    ($title->tc_start_frame or $title->tc_end_frame) ) {
		$self->message_window (
			message => __"You can't select a frame range with psu core."
		);
		return 1;
	}

	if ( $title->tc_psu_core and
	     $title->project->rip_mode ne 'rip' ) {
		$self->message_window (
			message => __"PSU core only available for ripped DVD's."
		);
		return 1;
	}

	if ( $title->tc_use_chapter_mode and not @{$chapters} ) {
		$self->message_window (
			message => __"No chapters selected."
		);
		return 1;
	}

	if ( $title->tc_use_chapter_mode and $split ) {
		$self->message_window (
			message => __"Splitting AVI files in\n".
                                    "chapter mode makes no sense."
		);
		return 1;
	}

	if ( $title->get_first_audio_track == -1 ) {
		$self->message_window (
			message => __"WARNING: no target audio track #0"
		);
	}

	if ( keys %{$title->get_additional_audio_tracks} ) {
		if ( $title->tc_video_codec =~ /^X?VCD$/ ) {
			$self->message_window (
				message =>
					__"Having more than one audio track ".
                                         "isn't possible on a (X)VCD."
			);
			return 1;
		}
		if ( $title->tc_video_codec =~ /^(X?SVCD|CVD)$/ and
		     keys %{$title->get_additional_audio_tracks} > 1 ) {
			$self->message_window (
				message =>
					__"WARNING: Having more than two audio tracks\n".
                                         "on a (X)SVCD/CVD is not standard conform. You may\n".
                                         "encounter problems on hardware players."
			);
		}
	}

	my $svcd_warning;
	if ( $svcd_warning = $title->check_svcd_geometry ) {
		$self->message_window (
			message =>
			       __x("WARNING {warning}\n", warning => $svcd_warning).
                               __"You better cancel now and select the appropriate\n".
                                 "preset on the Clip & Zoom page.",
		);
	}

	return $self->transcode_multipass_with_vbr_audio (
		subtitle_test => $subtitle_test
	) if not $subtitle_test
	     and $title->has_vbr_audio
	     and $title->tc_multipass
	     and not $title->multipass_log_is_reused;

	my $nr;
	my $job;
	my $last_job;
	my $exec = $self->new_job_executor;

	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::TranscodeVideo->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_chapter ($chapter);
		$job->set_subtitle_test ($subtitle_test);
		$job->set_split ($split);

		if ( not $subtitle_test and $title->tc_multipass ) {
			if ( $title->multipass_log_is_reused ) {
				$self->log (
					__"Skipping 1st pass as requested by ".
                                         "reusing existent multipass logfile."
				);
			} else {
				$job->set_pass (1);
				$last_job = $exec->add_job ( job => $job );
				$job = Video::DVDRip::Job::TranscodeVideo->new (
					nr            => ++$nr,
					title         => $title,
				);
			}
			$job->set_pass (2);
			$job->set_split ($split);
			$job->set_chapter ($chapter);
			$job->set_depends_on_jobs ( [ $last_job ] ) if $last_job;
			$last_job = $exec->add_job ( job => $job );
	
		} else {
			$job->set_single_pass(1);
			$last_job = $exec->add_job ( job => $job );
		}

		if ( $title->tc_container eq 'ogg' ) {
			$job = Video::DVDRip::Job::MergeAudio->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_vob_nr ( $title->get_first_audio_track );
			$job->set_avi_nr ( 0 );
			$job->set_chapter ($chapter);
			$job->set_subtitle_test ($subtitle_test);
			$last_job = $exec->add_job ( job => $job );
		}

		if ( not $subtitle_test ) {
			my $add_audio_tracks = $title->get_additional_audio_tracks;
			if ( keys %{$add_audio_tracks} ) {
				my ($avi_nr, $vob_nr);
				foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
					$vob_nr = $add_audio_tracks->{$avi_nr};

					$job = Video::DVDRip::Job::TranscodeAudio->new (
						nr    => ++$nr,
						title => $title,
					);
					$job->set_vob_nr ( $vob_nr );
					$job->set_avi_nr ( $avi_nr );
					$job->set_chapter ($chapter);
					$last_job = $exec->add_job ( job => $job );

					if ( not $mpeg ) {
						$job = Video::DVDRip::Job::MergeAudio->new (
							nr    => ++$nr,
							title => $title,
						);
						$job->set_vob_nr ( $vob_nr );
						$job->set_avi_nr ( $avi_nr );
						$job->set_chapter ($chapter);
						$last_job = $exec->add_job ( job => $job );
					}
				}
			}
		}

		if ( $mpeg ) {
			$job = Video::DVDRip::Job::Mplex->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_chapter ($chapter);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$job->set_subtitle_test ($subtitle_test);
			$last_job = $exec->add_job ( job => $job );
		}

		if ( not $subtitle_test and $split and not $mpeg ) {
			$job = Video::DVDRip::Job::Split->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$last_job = $exec->add_job ( job => $job );
		}
	}

	if ( $split ) {
		$last_job->set_cb_finished ( sub {
			$self->create_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	} else {
		$last_job->set_cb_finished ( sub {
			$self->create_non_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	}

	$exec->set_cb_finished (sub {
		return 1 if $exec->cancelled or $exec->errors_occured;
		return 1 if $subtitle_test;
		if ( $title->tc_execute_afterwards =~ /\S/ ) {
			system ("(".$title->tc_execute_afterwards.") &");
		}
		if ( $title->tc_exit_afterwards ) {
			$title->project->save
				if $title->tc_exit_afterwards ne 'dont_save';
			$self->get_context_object("main")->exit_program (
				force => ($title->tc_exit_afterwards eq 'dont_save')
			);
		}
		1;
	});

	$exec->execute_jobs;

	1;
}

sub transcode_multipass_with_vbr_audio {
	my $self = shift;

	$self->log (__"This title is transcoded with vbr audio ".
                     "and video bitrate optimization.");

	my $title    = $self->selected_title;
	my $chapters = $title->get_chapters;
	my $split    = $title->tc_split;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	my $bc = Video::DVDRip::BitrateCalc->new ( title => $title );

	my $nr;
	my $job;
	my $last_job;
	my $exec = $self->new_job_executor;

	# 1. encode additional audio tracks
	foreach my $chapter ( @{$chapters} ) {
		my $add_audio_tracks = $title->get_additional_audio_tracks;
		if ( keys %{$add_audio_tracks} ) {
			my ($avi_nr, $vob_nr);
			foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
				$vob_nr = $add_audio_tracks->{$avi_nr};
				$job = Video::DVDRip::Job::TranscodeAudio->new (
					nr    => ++$nr,
					title => $title,
				);
				$job->set_vob_nr  ( $vob_nr  );
				$job->set_avi_nr  ( $avi_nr  );
				$job->set_chapter ( $chapter );
				$job->set_bc      ( $bc      );
				$last_job = $exec->add_job ( job => $job );
			}
		}
	}
	
	# 2. 1st pass of Video + 1st Audio track
	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::TranscodeVideo->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_bc ($bc);
		$job->set_pass (1);
		$job->set_chapter ($chapter);
		$job->set_depends_on_jobs ( [ $last_job ] ) if $last_job;
		$last_job = $exec->add_job ( job => $job );
	}
	
	# 3. after 1st pass: calculate video bitrate (real audio size known)
	$last_job->set_cb_finished (sub {
		$bc->calculate;
		$title->set_tc_video_bitrate ( $bc->video_bitrate );
		$self->log (__x("Adjusted video bitrate to {video_bitrate} ".
			       "after vbr audio transcoding",
			       video_bitrate => $bc->video_bitrate) );
		$self->init_transcode_values;
		1;
	});
	
	# 4. 2nd pass Video and merging
	foreach my $chapter ( @{$chapters} ) {
		# transcode video 2nd pass
		$job = Video::DVDRip::Job::TranscodeVideo->new (
			nr            => ++$nr,
			title         => $title,
		);
		$job->set_pass (2);
		$job->set_chapter ($chapter);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$last_job = $exec->add_job ( job => $job );

		# merge 1st audio track
		$job = Video::DVDRip::Job::MergeAudio->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_vob_nr ( $title->get_first_audio_track );
		$job->set_avi_nr ( 0 );
		$job->set_chapter ($chapter);
		$last_job = $exec->add_job ( job => $job );

		# merge add. audio tracks
		my ($avi_nr, $vob_nr);
		my $add_audio_tracks = $title->get_additional_audio_tracks;
		foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
			$vob_nr = $add_audio_tracks->{$avi_nr};

			$job = Video::DVDRip::Job::MergeAudio->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_vob_nr ( $vob_nr );
			$job->set_avi_nr ( $avi_nr );
			$job->set_chapter ($chapter);
			$last_job = $exec->add_job ( job => $job );
		}

	}

	# 5. optional splitting (non chapter mode only)
	if ( $split ) {
		$job = Video::DVDRip::Job::Split->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$last_job = $exec->add_job ( job => $job );

		$last_job->set_cb_finished ( sub {
			$self->create_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	} else {
		$last_job->set_cb_finished ( sub {
			$self->create_non_splitted_vobsub (
				exec     => $exec,
				last_job => $last_job
			);
			1;
		} );
	}

	# 6. execute afterwards stuff
	$exec->set_cb_finished (sub {
		return 1 if $exec->cancelled or $exec->errors_occured;
		if ( $title->tc_execute_afterwards =~ /\S/ ) {
			system ("(".$title->tc_execute_afterwards.") &");
		}
		if ( $title->tc_exit_afterwards ) {
			$title->project->save
				if $title->tc_exit_afterwards ne 'dont_save';
			$self->get_context_object("main")->exit_program (
				force => ($title->tc_exit_afterwards eq 'dont_save')
			);
		}
		1;
	});

	$exec->execute_jobs;

	1;
}

sub avisplit {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if $self->progress_is_active;
	
	if ( $title->tc_use_chapter_mode ) {
		$self->message_window (
			message => __"Splitting an AVI file in\n".
                                    "Chapter Mode makes no sense."
		);
		return 1;
	}

	if ( not -f $title->avi_file ) {
		$self->message_window (
			message => __"You first have to transcode this title."
		);
		return 1;
	}

	my $nr;
	my $last_job;
	my $exec = $self->new_job_executor;
	my $job  = Video::DVDRip::Job::Split->new (
		nr    => ++$nr,
		title => $title,
	);

	$last_job = $exec->add_job ( job => $job );

	$last_job->set_cb_finished ( sub {
		$self->create_splitted_vobsub (
			exec     => $exec,
			last_job => $last_job
		);
		1;
	} );

	$exec->execute_jobs;

	1;
}

sub view_avi {
	my $self = shift;
	my %par = @_;
	my ($title) = @par{'title'};

	$title ||= $self->selected_title;
	return 1 if not $title;

	my $command = $title->get_view_avi_command (
		command_tmpl => $self->config('play_file_command'),
	);

	system ($command." &");
}

sub scan_rescale_volume {
	my $self = shift; $self->trace_in;

	my $title = $self->selected_title;
	return 1 if $self->progress_is_active;
	return 1 if not $title;

	if ( not $title->is_ripped ) {
		$self->message_window (
			message => __"You first have to rip this title."
		);
		return 1;
	}

	my $job;
	my $nr;
        my $chapter_count = 0;
	my $last_job;
	my $exec = $self->new_job_executor;

	my $chapters = $title->get_chapters;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::ScanVolume->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_chapter ($chapter);
		$job->set_count   ($chapter_count++);
		$last_job = $exec->add_job ( job => $job );
	}

	$exec->set_cb_finished (sub{
		$self->get_context->update_object_attr_widgets (
			"transcode.tc_volume_rescale",
		);
		1;
	});

	$exec->execute_jobs;

	1;
}

sub add_to_cluster {
	my $self = shift;
	
	$self->error_window (
		message => __"Not implemented yet",
	);
	return 1;

	my $title = $self->selected_title;
	return 1 if not $title;

	if ( $title->tc_use_chapter_mode ) {
		$self->message_window (
			message => __"Titles in chapter mode are not supported"
		);
		return 1;
	}

	if ( $title->tc_psu_core ) {
		$self->message_window (
			message => __"PSU core mode currently not supported"
		);
		return 1;
	}

	if ( $title->project->rip_mode ne 'rip' ) {
		$self->message_window (
			message => __"Cluster mode is only supported\nfor ripped DVD's."
		);
		return 1;
	}


	if ( not $title->is_ripped ) {
		$self->message_window (
			message => __"You first have to rip this title."
		);
		return 1;
	}

	if ( $title->get_first_audio_track < 0 ) {
		$self->message_window (
			message => __"You have no target audio track selected."
		);
		return 1;
	}

	if ( $title->tc_container eq 'vcd' ) {
		$self->message_window (
			message => __"MPEG processing is not supported for cluster mode."
		);
		return 1;
	}

	if ( $title->tc_start_frame ne '' or
	     $title->tc_end_frame ne '' ) {
		$self->message_window (
			message =>
				__"WARNING: your frame range setting\n".
                                 "is ignored in cluster mode"
		);
	}

	# calculate program stream units, if not already done
	$title->calc_program_stream_units
		if not $title->program_stream_units or
		   not @{$title->program_stream_units};

	$self->get_context_object("main")->cluster_control;
	
	my $cluster = eval { $self->get_context_object('cluster') };
	return if not $cluster;

	$cluster->add_project (
		project  => $self->project,
		title_nr => $title->nr,
	);
	
	1;
}

sub create_wav {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $nr;
	my $last_job;
	my $exec = $self->new_job_executor;

	my $chapters = $title->get_chapters;

	if ( not $title->tc_use_chapter_mode ) {
		$chapters = [ undef ];
	}

	my $job;
	foreach my $chapter ( @{$chapters} ) {
		$job  = Video::DVDRip::Job::CreateWav->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_chapter ( $chapter );
		$last_job = $exec->add_job ( job => $job );
	}

	$exec->execute_jobs;

	1;
}

sub open_video_configure_window {
	my $self = shift;

	my $title = $self->selected_title;
	return 1 if not $title;

	my $in_filename  = $title->multipass_log_dir."/xvid4.cfg";
	my $out_filename = $in_filename;

	if ( not -f $in_filename ) {
		system ("xvid4conf '$out_filename' '$ENV{HOME}/.transcode/xvid4.cfg' &");
	} else {
		system ("xvid4conf '$out_filename' '$in_filename' &");
	}

	1;
}

sub create_splitted_vobsub {
	my $self = shift;
	my %par = @_;
	my ($exec, $last_job) = @par{'exec','last_job'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if not $title->has_vobsub_subtitles;
	
	my $files = $title->get_split_files;

	if ( @{$files} == 0 ) {
		$self->message_window (
		    message =>
			__"No splitted target files available.\n".
			  "First transcode and split the movie."
		);
		
		return 1;
	}

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		if ( not -f $subtitle->ifo_file ) {
			$self->message_window (
			    message =>
				__"Need IFO files in place.\n".
				  "You must re-read TOC from DVD."
			);
			return 1;
		}
	}

	my $nr;
	my $job;
	$exec ||= $self->new_job_executor;

	$job  = Video::DVDRip::Job::CountFramesInFile->new (
		nr    => ++$nr,
		title => $title,
	);
	
	$job->set_depends_on_jobs ( [$last_job] ) if $last_job;
	
	my $count_job = $last_job = $exec->add_job ( job => $job );

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		next if not $subtitle->tc_vobsub;

		$job  = Video::DVDRip::Job::ExtractPS1->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_subtitle ( $subtitle );

		$job->set_depends_on_jobs ( [ $last_job ] );

		$last_job = $exec->add_job ( job => $job );

		my $file_nr = 0;
		foreach my $file ( @{$files} ) {
			$job  = Video::DVDRip::Job::CreateVobsub->new (
				nr    => ++$nr,
				title => $title,
			);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$job->set_subtitle ( $subtitle );
			$job->set_count_job ( $count_job );
			$job->set_file_nr ( $file_nr );
	
			$last_job = $exec->add_job ( job => $job );

			++$file_nr;
		}
	}

	$exec->execute_jobs;

	1;
}

sub create_non_splitted_vobsub {
	my $self = shift;
	my %par = @_;
	my ($exec, $last_job) = @par{'exec','last_job'};

	my $title = $self->selected_title;
	return 1 if not $title;
	return 1 if not $title->has_vobsub_subtitles;
	
	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		if ( not -f $subtitle->ifo_file ) {
			$self->message_window (
			    message =>
				__"Need IFO files in place.\n".
				  "You must re-read TOC from DVD."
			);
			return 1;
		}
	}

	my $nr;
	my $job;
	$exec ||= $self->new_job_executor;

	foreach my $subtitle ( sort { $a->id <=> $b->id }
			       values %{$title->subtitles} ) {
		next if not $subtitle->tc_vobsub;

		$job  = Video::DVDRip::Job::ExtractPS1->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_subtitle ( $subtitle );

		$last_job = $exec->add_job ( job => $job );

		$job  = Video::DVDRip::Job::CreateVobsub->new (
			nr    => ++$nr,
			title => $title,
		);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$job->set_subtitle ( $subtitle );
	
		$last_job = $exec->add_job ( job => $job );
	}

	$exec->execute_jobs;

	1;
}

1;
