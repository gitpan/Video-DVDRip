# $Id: Main.pm,v 1.37 2002/04/17 20:08:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Main;

use base Video::DVDRip::GUI::Component;

use Video::DVDRip;
use Video::DVDRip::Project;
use Video::DVDRip::GUI::Project;
use Video::DVDRip::GUI::Config;
use Video::DVDRip::GUI::ImageClip;

use strict;
use Data::Dumper;

use Gtk;
use Gtk::Keysyms;

use File::Basename;

sub gtk_box			{ shift->{gtk_box}			}
sub gtk_menubar			{ shift->{gtk_menubar}			}
sub gtk_greetings		{ shift->{gtk_greetings}		}
sub project_opened		{ shift->{project_opened}		}

sub set_gtk_box			{ shift->{gtk_box}		= $_[1] }
sub set_gtk_menubar		{ shift->{gtk_menubar}		= $_[1] }
sub set_gtk_greetings		{ shift->{gtk_greetings}	= $_[1] }
sub set_project_opened		{ shift->{project_opened}	= $_[1] }

sub start {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($filename, $open_cluster_control) =
	@par{'filename','open_cluster_control'};

	Gtk->init;
	Gtk::Widget->set_default_colormap(Gtk::Gdk::Rgb->get_cmap());
	Gtk::Widget->set_default_visual(Gtk::Gdk::Rgb->get_visual());

	$self->build if not $open_cluster_control;

	if ( $filename ) {
		$self->open_project_file (
			filename => $filename
		);
	}

	$self->cluster_control ( exit_on_close => 1 )
		if $open_cluster_control;

	$self->log ("Detected transcode version: ".$TC::VERSION);

	while ( 1 ) {
		eval { Gtk->main };
		if ( $@ =~ /^msg:\s*(.*)\s+at.*?line\s+\d+/s ) {
			$self->message_window (
				message => $1,
			);
			next;
		} elsif ( $@ ) {
			my $error =
				"An internal exception was thrown!\n".
				"The error message was:\n\n$@";

			$self->message_window (
				message => $error
			);
			next;
		} else {
			last;
		}
	}
}

sub build {
	my $self = shift; $self->trace_in;

	# create GTK widgets for main application window
	my $win       = $self->create_window;
	my $box       = $self->create_window_box;
	my $menubar   = $self->create_menubar;
	my $greetings = $self->create_greetings;

	$win->add ($box);
	$box->pack_start ($menubar, 0, 1, 0);
	$box->pack_start ($greetings, 1, 0, 0);

	$self->set_gtk_greetings ($greetings);

	# store component
	$self->set_comp ( main => $self );

	$self->set_widget($win);

	$win->show;

	return 1;
}

sub create_greetings {
	my $self = shift;
	
	my $splash_file;
	foreach my $INC ( @INC ) {
		$splash_file = "$INC/Video/DVDRip/splash.png";
		last if -f $splash_file;
		$splash_file = "";
	}

	if ( not $splash_file ) {
		my $text = <<__EOT;
dvd::rip - A full featured DVD Ripper GUI for Linux

Version $Video::DVDRip::VERSION

Copyright (c) 2001-2002 Joern Reder, All Rights Reserved

http://www.exit1.org/dvdrip/

dvd::rip is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

__EOT
		my $label = Gtk::Label->new ($text);
		$label->show;

		return $label;
	}

	my $image = Video::DVDRip::GUI::ImageClip->new (
		gtk_window => $self->widget,
		width      => 400,
		height     => 300,
		thumbnail  => 1,
		no_clip    => 1,
	);
	$image->load_image (
		filename => $splash_file
	);
	$image->draw;

	my $hbox = Gtk::HBox->new (1, 0);
	$hbox->show;
	$hbox->pack_start ($image->widget, 1, 0, 0);

	return $hbox;
}

sub create_window {
	my $self = shift; $self->trace_in;
	
	my $win = new Gtk::Window -toplevel;
	$win->set_title($self->config('program_name'));
	$win->signal_connect("destroy", sub { $self->exit_program (force => 1) } );
	$win->border_width(0);
	$win->set_uposition (10,10);
	$win->set_default_size (
		$self->config('main_window_width'),
		$self->config('main_window_height'),
	);
	$win->realize;

	$win->signal_connect("size-allocate",
		sub {
			$self->set_config('main_window_width', $_[1]->[2]);
			$self->set_config('main_window_height', $_[1]->[3]);
		}
	);

	$self->set_gtk_win ($win);
	
	return $win;
}	

sub create_window_box {
	my $self = shift; $self->trace_in;
	
	my $box = new Gtk::VBox (0, 2);
	$box->show;
	
	$self->set_gtk_box ($box);
	
	return $box;
}

sub create_menubar {
	my $self = shift; $self->trace_in;
	
	my $win = $self->gtk_win;
	
	my @menu_items = (
		{ path        => '/_File',
                  type        => '<Branch>' },

                { path        => '/File/_New Project',
		  accelerator => '<control>n',
                  callback    => sub { $self->new_project } },
                { path        => '/File/_Open Project...',
		  accelerator => '<control>o',
                  callback    => sub { $self->open_project } },
                { path        => '/File/_Save Project',
		  accelerator => '<control>s',
                  callback    => sub { $self->save_project } },
                { path        => '/File/Save Project As...',
                  callback    => sub { $self->save_project_as } },
                { path        => '/File/_Close Project',
		  accelerator => '<control>w',
                  callback    => sub { $self->close_project } },

		{ path	      => '/File/sep_quit',
		  type	      => '<Separator>' },
                { path        => '/File/_Exit',
		  accelerator => '<control>Q',
                  callback    => sub { $self->exit_program } },

		{ path        => '/_Edit',
                  type        => '<Branch>' },

                { path        => '/_Edit/Edit _Preferences...',
		  accelerator => '<control>p',
                  callback    => sub { $self->edit_preferences } },

		{ path        => '/_Cluster',
                  type        => '<Branch>' },

                { path        => '/_Cluster/Contro_l...',
		  accelerator => '<control>m',
                  callback    => sub { $self->cluster_control } },

		{ path        => '/_Debug',
                  type        => '<Branch>' },

                { path        => '/_Debug/Show _Transcode commands...',
		  accelerator => '<control>t',
                  callback    => sub { $self->show_transcode_commands } },
	);

	my $accel_group = Gtk::AccelGroup->new;
	my $item_factory = Gtk::ItemFactory->new (
		'Gtk::MenuBar',
		'<main>',
		$accel_group
	);
	$item_factory->create_items ( @menu_items );
	$win->add_accel_group ( $accel_group );
	my $menubar = $self->set_gtk_menubar ( $item_factory->get_widget( '<main>' ) );
	$menubar->show;

	return $menubar;
}

sub new_project {
	my $self = shift;
	
	return if $self->unsaved_project_open (
		wants => "new_project"
	);
	
	$self->close_project;

	my $project = Video::DVDRip::Project->new (
		name => 'unnamed',
	);

	$project->set_vob_dir (
		$self->config('base_project_dir')."/unnamed/vob",
	);
	$project->set_avi_dir (
		$self->config('base_project_dir')."/unnamed/avi",
	);
	$project->set_snap_dir (
		$self->config('base_project_dir')."/unnamed/tmp",
	);
	$project->set_dvd_device (
		$self->config('dvd_device'),
	);
	
	my $project_gui = Video::DVDRip::GUI::Project->new;
	$project_gui->set_project ( $project );

	$self->gtk_greetings->hide;
	$self->gtk_box->pack_start ($project_gui->build, 1, 1, 1);
	
	$self->set_project_opened(1);
	
	$self->set_window_title;

	1;
}

sub set_window_title {
	my $self = shift;

	my $filename = basename($self->comp('project')->project->filename) ||
		       "<unnamed project>";

	$self->widget->set_title (
		$self->config('program_name')." - ".$filename
	);
	
	1;
}


sub open_project {
	my $self = shift;

	return if $self->unsaved_project_open (
		wants => "open_project"
	);
	
	$self->show_file_dialog (
		dir      => ".",
		filename => "",
		cb       => sub {
			$self->open_project_file ( filename => $_[0] );
		},
	);
}

sub open_project_file {
	my $self = shift;
	my %par = @_;
	my ($filename) = @par{'filename'};
	
	if ( not -r $filename ) {
		$self->message_window (
			message => "File '$filename' not found or not readable."
		);
		return 1;
	}

	my $project = Video::DVDRip::Project->new_from_file (
		filename => $filename
	);

	my $project_gui = Video::DVDRip::GUI::Project->new;
	$project_gui->set_project ( $project );

	$self->gtk_greetings->hide;
	$self->gtk_box->pack_start ($project_gui->build, 1, 1, 1);
	$project_gui->fill_with_values;

	$self->set_project_opened(1);

	$project_gui->show_preview_images;

	$self->set_window_title;

	$project->set_dvd_device (
		$self->config('dvd_device')
	);

	1;
}

sub save_project {
	my $self = shift;
	
	return if not $self->project_opened;

	if ( $self->comp('project')->project->filename ) {
		$self->comp('project')->project->save;
		$self->set_window_title;
		return 1;

	} else {
		$self->show_file_dialog (
			dir      => ".",
			filename => $self->comp('project')->project->name.".rip",
			confirm  => 1,
			cb       => sub {
				$self->comp('project')->project->set_filename($_[0]);
				$self->comp('project')->project->save;
				$self->set_window_title;
			},
		);
		return 1;
	}
}

sub save_project_as {
	my $self = shift;
	
	return if not $self->project_opened;

	$self->show_file_dialog (
		dir      => ".",
		filename => $self->comp('project')->project->name.".rip",
		confirm  => 1,
		cb       => sub {
			$self->comp('project')->project->set_filename($_[0]);
			$self->comp('project')->project->save;
			$self->set_window_title;
		},
	);

	return 1;
}

sub close_project {
	my $self = shift;
	my %par = @_;
	my ($dont_ask) = @par{'dont_ask'};
	
	return if not $self->project_opened;
	return if not $dont_ask and $self->unsaved_project_open;
	
	$self->comp('project')->close;
	$self->gtk_box->remove ($self->comp('project')->widget);
	$self->comp( project => undef );
	$self->set_project_opened (0);
	$self->gtk_greetings->show;

	1;
}

sub unsaved_project_open {
	my $self = shift;
	my %par = @_;
	my ($wants) = @par{'wants'};
	
	return if not $self->project_opened;
	if ( not $self->comp('project')->project->changed ) {
		$self->close_project ( dont_ask => 1 );
		return;
	}

	$self->confirm_window (
		message => "Do you want to save this project first?",
		yes_label => "Yes",
		no_label => "No",
		yes_callback => sub {
			if ( $self->save_project ) {
				$self->close_project ( dont_ask => 1 );
				$self->$wants() if $wants;
			}
		},
		no_callback => sub {
			$self->close_project ( dont_ask => 1 );
			$self->$wants() if $wants;
		},
	);
	
	1;
}

sub exit_program {
	my $self = shift;
	my %par = @_;
	my ($force) = @par{'force'};

	return if not $force and $self->unsaved_project_open (
		wants => "exit_program"
	);

	if ( $self->project_opened ) {
		$self->comp('project')->close if $self->comp('project');
	}

	Gtk->exit( 0 ); 
}

sub edit_preferences {
	my $self = shift;
	
	my $pref = Video::DVDRip::GUI::Config->new;
	$pref->open_window;
	
	1;
}

sub cluster_control {
	my $self = shift;
	my %par = @_;
	my ($exit_on_close) = @par{'exit_on_close'};

	require Video::DVDRip::GUI::Cluster::Control;

	if ( ($self->config('cluster_master_local') or
	      $self->config('cluster_master_server')) and
	      $self->config('cluster_master_port') ) {

		my $cluster = Video::DVDRip::GUI::Cluster::Control->new;
		$cluster->set_exit_on_close ($exit_on_close);
		$cluster->open_window;

	} else {
		$self->message_window (
			message => "You must first configure a cluster control daemon\n".
				   "in the Preferences dialog.",
		);
	}

	1;
}

sub show_transcode_commands {
	my $self = shift;
	
	my $title = eval { $self->comp('project')->selected_title };
	return if not $title or $@;

	my $commands = "";
	
	$commands .= "Probe Command:\n".
		     "==============\n".
		     $title->get_probe_command()."\n";

	$commands .= "\n\n";

	my $rip_method = $title->tc_use_chapter_mode ?
		"get_rip_command" :
		"get_rip_and_scan_command";

	$commands .= "Rip Command:\n".
		    "============\n".
		    $title->$rip_method()."\n";

	$commands .= "\n\n";
	
	$commands .= "Grab Preview Image Command:\n".
		    "===========================\n".
		    $title->get_take_snapshot_command(
		    	frame => $title->preview_frame_nr
		    )."\n";

	$commands .= "\n\n";
	
	$commands .= "Transcode Command:\n".
		     "==================\n";

	if ( $title->tc_multipass ) {
		$commands .= $title->get_transcode_command ( pass => 1 )."\n".
			     $title->get_transcode_command ( pass => 2 )."\n";
	} else {
		$commands .= $title->get_transcode_command()."\n";
	}
	
	if ( $title->tc_video_codec =~ /^S?VCD$/ ) {
		$commands .= "\n".$title->get_mplex_command( split => 1 ),"\n";
	}

	$self->long_message_window (
		message => $commands
	);
	
	1;
}

1;
