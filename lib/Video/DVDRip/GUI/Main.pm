# $Id: Main.pm,v 1.54.2.1 2002/11/23 13:40:48 joern Exp $

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
use Video::DVDRip::GUI::CheckedEntry;

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
	my  ($filename, $open_cluster_control, $function, $select_title) =
	@par{'filename','open_cluster_control','function','select_title'};

	Gtk->init;

#Gtk::Rc->parse_string(<<"EOF");
#style "user-font"
#{
#  fontset="-adobe-helvetica-medium-r-normal-*-*-100-*-*-*-*-*-*"
#}
#widget_class "*" style "user-font"
#EOF

	Gtk::Widget->set_default_colormap(Gtk::Gdk::Rgb->get_cmap());
	Gtk::Widget->set_default_visual(Gtk::Gdk::Rgb->get_visual());

	$self->build if not $open_cluster_control;

	my $project;
	if ( $filename ) {
		$self->open_project_file (
			filename => $filename
		);
		eval { $project = $self->comp('project')->project };
	}

	$self->log (
		"Detected transcode version: $TC::ORIG_VERSION (=> $TC::VERSION)"
	);
	$self->log (
		"Detected subtitleripper version: $STR::VERSION"
	);

	$self->check_annoying_red_hat_8_0_perl_BUG;

	# Open Cluster Control window, if requested
	$self->cluster_control ( exit_on_close => 1 )
		if $open_cluster_control;

	# Error check

	if ( ($select_title or $function) and not $project
	      and $function ne 'preferences' ) {
		print STDERR "Opening project file failed. Aborting.\n";
		exit 1;
	}

	# Select a title, if requested
	if ( $select_title ) {
		$self->log ("Selecting title $select_title");
		my $title = $project->content->titles->{$select_title};
		if ( $title ) {
			# unselect old title
			$self->comp('project')
			     ->rip_title_widgets
			     ->{content_clist}
			     ->unselect_row ($project->selected_title_nr-1, 1);
			# select new title
			$self->comp('project')
			     ->rip_title_widgets
			     ->{content_clist}
			     ->select_row ($select_title-1, 1);
		} else {
			print STDERR "Can't select title $select_title. Aborting.\n";
			exit 1;
		}
	}

	# Execute a function, if requested
	if ( $function eq 'preferences' ) {
		$self->edit_preferences;
	} elsif ( $function ) {
		my $title = $self->comp('project')->selected_title;
		$self->comp('project')->gtk_notebook->set_page( 3 );
		$title->set_tc_exit_afterwards('dont_save');
		if ( $function eq 'transcode' ) {
			$self->comp('project')->transcode;
		} elsif ( $function eq 'transcode_split' ) {
			$self->comp('project')->transcode ( split => 1 );
		}
	}

	while ( 1 ) {
		$self->print_debug ("Entering Gtk->main loop");
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
			$self->long_message_window (
				message => $error
			);
			my $progress = eval { $self->comp('progress') };
			$progress->cancel if $progress and $progress->is_active;
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
	
	my $splash_file = $self->search_perl_inc (
		rel_path => "Video/DVDRip/splash.png"
	);

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
	
	my $win = Gtk::Window->new;
	$win->set_title($self->config('program_name'));
	$win->signal_connect("delete-event", sub { $self->exit_program (force => 0) } );
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

	# set window manager icon

	my $icon_file = $self->search_perl_inc (
		rel_path => "Video/DVDRip/icon.xpm"
	);

	if ( $icon_file ) {
		my ($icon, $mask) = Gtk::Gdk::Pixmap->create_from_xpm(
			$win->window,
			$win->style->white,
			$icon_file
		);
		
		$win->window->set_icon(undef, $icon, $mask);
		$win->window->set_icon_name("dvd::rip");
	}

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

		{ path        => '/_Operate',
                  type        => '<Branch>' },

                { path        => '/_Operate/Transcode and split',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->transcode ( split => 1 )
		} },
                { path        => '/_Operate/Transcode',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->transcode
		} },
                { path        => '/_Operate/Split target file',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->avisplit
		} },
                { path        => '/_Operate/View target file',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->view_avi
		} },
                { path        => '/_Operate/Add project to cluster',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->add_to_cluster
		} },
                { path        => '/_Operate/Create splitted _vobsub(s)',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->create_splitted_vobsub
		} },
                { path        => '/_Operate/Create non-splitted _vobsub(s)',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
		  	$self->comp('project')->create_non_splitted_vobsub
		} },
                { path        => '/_Operate/Create dvdrip-info file',
                  callback    => sub {
		  	return 1 if not $self->project_opened;
			my $title = $self->comp('project')->selected_title;
			return 1 if not $title;
			Video::DVDRip::InfoFile->new (
				title    => $title,
				filename => $title->info_file,
			)->write;
			1;
		} },


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

	if ( not $self->project_opened ) {
		$self->widget->set_title (
			$self->config('program_name')
		);
		return 1;
	}

	my $filename = basename(
		$self->comp('project')->project->filename ||
		"<unnamed project>"
	);

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
	
	$self->close_project;
	
	$self->show_file_dialog (
		dir      => $self->config('dvdrip_files_dir'),
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

	$self->set_project_opened(1);

	$project_gui->show_preview_images;

	$self->set_window_title;
	$self->comp('progress')->set_idle_label;

	$project->set_dvd_device (
		$self->config('dvd_device')
	);

	if ( $project->convert_message ) {
		$self->message_window (
			message => $project->convert_message
		);
		$project->set_convert_message("");
	}

	$project_gui->gtk_notebook->set_page ( $project->last_selected_nb_page );

	1;
}

sub save_project {
	my $self = shift;
	
	return if not $self->project_opened;

	if ( $self->comp('project')->project->filename ) {
		$self->comp('project')->project->set_last_selected_nb_page (
			$self->comp('project')->gtk_notebook->get_current_page
		);
		$self->comp('project')->project->save;
		$self->set_window_title;
		return 1;

	} else {
		$self->show_file_dialog (
			dir      => $self->config('dvdrip_files_dir'),
			filename => $self->comp('project')->project->name.".rip",
			confirm  => 1,
			cb       => sub {
				$self->comp('project')->project->set_filename($_[0]);
				$self->save_project;
			},
		);
		return 0;
	}
}

sub save_project_as {
	my $self = shift;
	
	return if not $self->project_opened;

	$self->show_file_dialog (
		dir      => $self->config('dvdrip_files_dir'),
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
	$self->set_window_title;

	1;
}

sub unsaved_project_open {
	my $self = shift;
	my %par = @_;
	my ($wants) = @par{'wants'};
	
	return if not $self->project_opened;
	return if not $self->comp('project')->project->changed;

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

	return 1 if not $force and $self->unsaved_project_open (
		wants => "exit_program"
	);

	$self->close_project ( dont_ask => $force );

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

	if ( $title->project->rip_mode eq 'rip' ) {
		my $rip_method = $title->tc_use_chapter_mode ?
			"get_rip_command" :
			"get_rip_and_scan_command";
	
		$commands .= "Rip Command:\n".
			    "============\n".
			    $title->$rip_method()."\n";
	} else {
		$commands .= "Scan Command:\n".
			    "============\n".
			    $title->get_scan_command()."\n";
	}

	$commands .= "\n\n";
	
	$commands .= "Grab Preview Image Command:\n".
		    "===========================\n";

	eval {
		$commands .=
		    $title->get_take_snapshot_command(
		    	frame => $title->preview_frame_nr
		    )."\n";
	};
	
	if ( $@ ) {
		$commands .=
			"You must first rip the selected title ".
			"to see this command.\n";
	}
	
	$commands .= "\n\n";
	
	$commands .= "Transcode Command:\n".
		     "==================\n";

	if ( $title->tc_multipass ) {
		$commands .= $title->get_transcode_command ( pass => 1, split => 1 )."\n".
			     $title->get_transcode_command ( pass => 2, split => 1 )."\n";
	} else {
		$commands .= $title->get_transcode_command( split => 1 )."\n";
	}
	
	if ( $title->tc_video_codec =~ /^S?VCD$/ ) {
		$commands .= "\n".$title->get_mplex_command( split => 1 ),"\n";
	}

	if ( $title->tc_audio_codec eq 'ogg' ) {
		$commands .= "\n".$title->get_merge_audio_command (
			vob_nr => $title->get_first_audio_track,
			avi_nr => 0,
		),"\n";
	}

	$commands .= "\n\n";

	my $add_audio_tracks = $title->get_additional_audio_tracks;

	if ( keys %{$add_audio_tracks} ) {
		$commands .= "Additional audio tracks commands:\n".
			     "============================\n";

		my ($avi_nr, $vob_nr);
		while ( ($avi_nr, $vob_nr) = each %{$add_audio_tracks} ) {
			$commands .= "\n".$title->get_transcode_audio_command (
				vob_nr => $vob_nr,
				target_nr => $avi_nr,
			)."\n";
			$commands .= "\n".$title->get_merge_audio_command (
				vob_nr => $vob_nr,
				target_nr => $avi_nr,
			);
		}
		
		$commands .= "\n\n";
	}

	$commands .= "View DVD Command:\n".
		     "=================\n".
		     $title->get_view_dvd_command(
		     	command_tmpl => $self->config('play_dvd_command')
		     )."\n";

	$commands .= "\n\n";

	$commands .= "View Files Command:\n".
		     "===================\n".
		     $title->get_view_avi_command(
		     	command_tmpl => $self->config('play_file_command'),
			file => "movie.avi",
		     )."\n";

	my $create_image_command;
	eval {
		$create_image_command = $title->get_create_image_command;
	};
	$create_image_command = $self->stripped_exception if $@;

	my $burn_command;
	eval {
		$burn_command = $title->get_burn_command;
	};
	$burn_command = $self->stripped_exception if $@;

	$commands .= "\n\n";
	
	$commands .= "CD image creation command:\n".
		     "========================\n".
		     $create_image_command;

	$commands .= "\n\n";
	
	$commands .= "CD burning command:\n".
		     "==================\n".
		     $burn_command;

	$self->long_message_window (
		message => $commands
	);
	
	1;
}

sub check_annoying_red_hat_8_0_perl_BUG {
	my $self = shift;

	my $warn = 0;

	if ( -x "/bin/rpm" ) {
		my $rh_release = qx[/bin/rpm -q redhat-release];
		if ( $rh_release =~ /8\.0/ ) {
			if ( $ENV{PERLIO} ne 'stdio' and
			     not -f "$ENV{HOME}/.dvdrip-no-rh8-warn" ) {
			     	$warn = 1;
			}
		}
	}

	$self->long_message_window (
	    message =>
		"You're running RedHat 8.0. The Perl version of this RedHat\n".
		"release is broken. If you get errors when reading the DVD TOC,\n".
		"set the following environment variable, before starting dvd::rip:\n".
		"\n".
		"  export PERLIO=stdio\n".
		"\n".
		"If your RedHat version works without this environment variable,\n".
		"they obviously fixed the bug in the meantime. Execute the following\n".
		"command to get rid of this warning message:\n".
		"\n".
		"  touch ~/.dvdrip-no-rh8-warn"
	) if $warn;
	
	1;
}

1;
