# $Id: Filters.pm,v 1.13 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Filters;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $filters_ff;

sub open_window {
    my $self = shift;

    return if $filters_ff;

    $self->build;

    1;
}

sub build {
    my $self = shift;

    my $context = $self->get_context;

    $filters_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        parent_ff => $self->get_form_factory,
        sync      => 0,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __ "dvd::rip - Filters & Preview",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
#                        default_width  => 640,
                        default_height => 480,
                    );
                    1;
                },
                closed_hook => sub {
                    $filters_ff->close if $filters_ff;
                    $filters_ff = undef;
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::Table->new(
                        expand => 1,
                        layout => q{
                            +>-------------------+--------------------+
                            ^ Available filters  | Selected filters   |
                            |                    |                    |
                            +--------------------+--------------------+
                            ^ Filter options                          |
                            |                                         |
                            +----------------+>-----------------------+
                            | Prev. settings | Preview control        |
                            +----------------+------------------------+
			},
                        content => [
                            $self->build_available_filters_box,
                            $self->build_selected_filters_box,
                            $self->build_filter_options_box,
                            $self->build_preview_settings_box,
                            $self->build_preview_control_box,
                        ],
                    ),
                ],
            ),

        ],
    );

    $filters_ff->build;
    $filters_ff->update;
    $filters_ff->show;

    1;
}

sub build_available_filters_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Available filters",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::List->new (
                attr       => "filter_list.filters",
                columns    => [ __"Name", __"Description" ],
                scrollbars => [ "automatic", "automatic" ],
                expand     => 1,
                tip        => __"Double click a row to activate a filter",
            ),
        ],
    );
}

sub build_selected_filters_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Selected filters",
        expand => 1,
    );
}

sub build_filter_options_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Filter options",
        expand => 1,
    );
}

sub build_preview_settings_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Preview settings",
        expand  => 0,
        content => [
            Gtk2::Ex::FormFactory::Combo->new (
                attr => "title.tc_preview_buffer_frames",
                tip  => __("Frames buffered in the preview window ".
                           "and thus are available for scrubbing"),
                presets => [ 20, 50, 100, 150, 200],
                width => 60,
            ),
            Gtk2::Ex::FormFactory::Entry->new (
                attr  => "title.tc_preview_start_frame",
                tip   => __"Preview should start at this frame",
                width => 40,
            ),
            Gtk2::Ex::FormFactory::Label->new (
                label => " - ",
            ),
            Gtk2::Ex::FormFactory::Entry->new (
                attr => "title.tc_preview_end_frame",
                tip  => __"Preview should start stop this frame",
                width => 40,
            ),
        ],
    );
}

sub build_preview_control_box {
    my $self = shift;

    my $active_when_preview_open = sub {
        $self->get_context_object("preview_window") ? 1 : 0;
    };
    my $active_when_preview_closed = sub {
        $self->get_context_object("preview_window") ? 0 : 1;
    };

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Preview control",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-play",
                label => "",
                tip   => __"Open preview window and play",
                active_cond    => $active_when_preview_closed,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_play },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-apply",
                label => "",
                tip   => __"Apply filter chain",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-undo",
                label => "",
                tip   => __"Undo - view previous buffer",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-remove",
                label => "",
                tip   => __"Decrease preview speed",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-add",
                label => "",
                tip   => __"Increase preview speed",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-pause",
                label => "",
                tip   => __"Pause/Resume",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_pause },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-rewind",
                label => "",
                tip   => __"Step backward one frame",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-forward",
                label => "",
                tip   => __"Step forward one frame",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-goto-first",
                label => "",
                tip   => __"Step backward several frames",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-goto-last",
                label => "",
                tip   => __"Step forward several frames",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-stop",
                label => "",
                tip   => __"Stop playing and close preview window",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_stop },
            ),
       ],
    );
}

sub get_transcode_remote {
    my $self = shift;
    
    return $self->get_context_object("preview_window")
                ->transcode_remote
}

sub preview_play {
    my $self = shift;

    require Video::DVDRip::GUI::Preview;

    my $preview = Video::DVDRip::GUI::Preview->new (
        context   => $self->get_context,
	closed_cb => sub {
	    $self->preview_stop
	},
	selection_cb => sub { $self->preview_selection ( @_ ) },
	eof_cb => sub {
	    $self->preview_stop;
	    Gtk->timeout_add (1000, sub {
		$self->preview_play;
		return 0;
	    });
	},
    );

    $self->get_context->set_object ( "preview_window" => $preview );

    $preview->open;

    1;
}

sub preview_stop {
    my $self = shift;
    
    my $preview = $self->get_context_object("preview_window");
    $self->get_context->set_object ( "preview_window" => 0 );
    
    $preview->stop;
    
    1;
}

sub preview_slower {
    my $self = shift;

    $self->get_transcode_remote->preview( command => "slower", );

    1;
}

sub preview_faster {
    my $self = shift;

    $self->get_transcode_remote->preview( command => "faster", );

    1;
}

sub preview_pause {
    my $self = shift;

    my $context = $self->get_context;
    
    $context->get_object("preview_window")->pause;
    $context->update_object_widgets("preview_window");

    1;
}

1;

