# $Id: Title.pm,v 1.9 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Title;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

sub multi_instance_window { 1 }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

sub master			{ shift->{master}			}
sub set_master			{ shift->{master}		= $_[1] }

sub title			{ shift->{title}			}
sub set_title			{ shift->{title}		= $_[1] }

sub title_data			{ shift->{title_data}			}
sub set_title_data		{ shift->{title_data}		= $_[1] }

# GUI Stuff ----------------------------------------------------------

sub new {
	my $class = shift;
	my %par = @_;
	my  ($master, $title) =
	@par{'master','title'};
	
	my $self = $class->SUPER::new (@_);

	$self->set_master ($master);
	$self->set_title ($title);

	my %selected_psu;
	foreach my $psu ( @{$title->program_stream_units} ) {
		$selected_psu{$psu->nr} = 1 if $psu->selected;
	}

	$self->set_title_data ({
		with_avisplit    => $title->with_avisplit,
		with_cleanup     => $title->with_cleanup,
		with_vob_remove  => $title->with_vob_remove,
		selected_psu     => \%selected_psu,
		frames_per_chunk => $title->frames_per_chunk,
	});

	return $self;
}

sub build {
	my $self = shift; $self->trace_in;

	my $title = $self->title;
	my $title_data = $self->title_data;
	my $what = $title->project->state eq 'not scheduled' ? "Edit" : "View";

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " $what Cluster Project");
	$win->border_width(0);
	$win->set_uposition (10,10);
	$win->realize;

	$self->set_gtk_widgets ({});

	# Build dialog -----------------------------------------------
	my $dialog_vbox = Gtk::VBox->new;
	$dialog_vbox->show;
	$dialog_vbox->set_border_width(10);
	$win->add($dialog_vbox);

	my ($frame, $vbox, $hbox, $button);

	# Edit Title Attributes --------------------------------------
	
	$frame = Gtk::Frame->new ("Cluster Project Properties");
	$frame->show;
	$dialog_vbox->pack_start($frame, 0, 1, 0);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);

	my @fields = (
		{
			label => "Project",
			type => "string",
			value => $title->project->label,
			readonly => 1,
		},
		{
			label => "Number of frames per chunk",
			type => "text",
			value => $title->frames_per_chunk,
			onchange => sub {
				$title_data->{frames_per_chunk} = $_[0]->get_text;
			},
			width => 80,
			readonly => ($title->project->state ne 'not scheduled'),
		},
		{
			label => "Do avisplit after transcoding?",
			type => "switch",
			value => $title->with_avisplit,
			onchange => sub {
				$title_data->{with_avisplit} = $_[0];
			},
			readonly => ($title->project->state ne 'not scheduled'),
		},
		{
			label => "Cleanup temp. AVI chunk files after merging?",
			type => "switch",
			value => $title->with_cleanup,
			onchange => sub {
				$title_data->{with_cleanup} = $_[0];
			},
			readonly => ($title->project->state ne 'not scheduled'),
		},
		{
			label => "Cleanup VOB files when finished?",
			type => "switch",
			value => $title->with_vob_remove,
			onchange => sub {
				$title_data->{with_vob_remove} = $_[0];
			},
			readonly => ($title->project->state ne 'not scheduled'),
		},
	);

	my $table = $self->create_dialog ( @fields );
	$vbox->pack_start ($table, 0, 1, 0);

	# Program Stream Units: DISABLED
if ( 0 ) {
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );
	$sw->set_usize(120, 80);
	$hbox->pack_start ($sw, 0, 1, 0);

	my $psu_clist = Gtk::CList->new_with_titles ( "Nr", "Frames" );
	$sw->add( $psu_clist );
	$psu_clist->set_selection_mode( 'extended' );
	$psu_clist->set_shadow_type( 'none' );
	$psu_clist->set_column_width (0, 30);
	$psu_clist->show();
	$psu_clist->signal_connect ("select_row",   sub { $self->title_data->{selected_psu}->{$_[1]} = 1 } );
	$psu_clist->signal_connect ("unselect_row", sub { $self->title_data->{selected_psu}->{$_[1]} = 0 } );

	my $label = Gtk::Label->new ("Select the program stream units\nwhich should be processed.");
	$label->show;
	$hbox->pack_start ($label, 0, 1, 0);

	foreach my $psu ( @{$title->program_stream_units} ) {
		$psu_clist->append (
			$psu->nr,
			$psu->frames,
		);
		$psu_clist->select_row ( $psu->nr, 0 ) if $psu->selected;
	}
}

	# Buttons
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);

	if ( $title->project->state eq 'not scheduled' ) {
		$button = Gtk::Button->new_with_label ("      Ok      ");
		$button->show;
		$button->signal_connect ( "clicked", sub { $self->dialog_ok } );
		$hbox->pack_start ($button, 0, 1, 0);
	}

	$button = Gtk::Button->new_with_label ("    Cancel    ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->dialog_cancel } );
	$hbox->pack_start ($button, 0, 1, 0);

	# Register component and window ------------------------------
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);

	$win->show;

	return 1;
}

sub dialog_ok {
	my $self = shift;

	my $title = $self->title;
	my $title_data = $self->title_data;

	# check psu changes: DISABLED
if ( 0 ) {
	my $psu_changed;
	my $psu_cnt;

	foreach my $psu ( @{$title->program_stream_units} ) {
		++$psu_cnt if $title_data->{selected_psu}->{$psu->nr};
	};

	if ( not $psu_cnt ) {
		$self->message_window (
			message => "You must at least select one program stream unit",
		);
		return 1;
	}

	foreach my $psu ( @{$title->program_stream_units} ) {
		if ( $psu->selected != $title_data->{selected_psu}->{$psu->nr} ) {
			$psu->set_selected ($title_data->{selected_psu}->{$psu->nr});
			$psu_changed = 1;
		}
	};
}

	# copy data fields into title object
	my ($k, $v);
	my $set_method;

	while ( ($k, $v) = each %{$title_data} ) {
		next if $k eq 'selected_psu';
		$set_method = "set_".$k;
		$title->$set_method ($v) if $v ne $title->$k ();
	}

	# create the job plan
	$title->project->create_job_plan;

	# save changes
	$title->save;

	$self->comp('cluster')->update_job_list;

	$self->gtk_window_widget->destroy;

	1;
}

sub dialog_cancel {
	my $self = shift;
	
	$self->gtk_window_widget->destroy;
	
	1;
}

1;
