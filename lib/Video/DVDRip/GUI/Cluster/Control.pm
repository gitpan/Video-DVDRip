# $Id: Control.pm,v 1.21 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Control;

use base Video::DVDRip::GUI::Window;

use Video::DVDRip::RPC::Client;
use Video::DVDRip::GUI::Cluster::Node;
use Video::DVDRip::GUI::Cluster::Title;

use strict;
use Carp;

sub single_instance_window { 1 }

sub rpc_server			{ shift->{rpc_server}			}
sub set_rpc_server		{ shift->{rpc_server}		= $_[1] }

sub master			{ shift->{master}			}
sub set_master			{ shift->{master}		= $_[1] }

sub log_socket			{ shift->{log_socket}			}
sub set_log_socket		{ shift->{log_socket}		= $_[1] }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

sub selected_project		{ shift->{selected_project}		}
sub set_selected_project	{ shift->{selected_project}	= $_[1] }

sub selected_project_row	{ shift->{selected_project_row}		}
sub set_selected_project_row	{ shift->{selected_project_row}	= $_[1] }

sub selected_job_id		{ shift->{selected_job_id}		}
sub set_selected_job_id		{ shift->{selected_job_id}	= $_[1] }

sub selected_job_row		{ shift->{selected_job_row}		}
sub set_selected_job_row	{ shift->{selected_job_row}	= $_[1] }

sub selected_node		{ shift->{selected_node}		}
sub set_selected_node		{ shift->{selected_node}	= $_[1] }

sub selected_node_row		{ shift->{selected_node_row}		}
sub set_selected_node_row	{ shift->{selected_node_row}	= $_[1] }

sub exit_on_close		{ shift->{exit_on_close}		}
sub set_exit_on_close		{ shift->{exit_on_close}	= $_[1] }

# GUI Stuff ----------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	$self->set_gtk_widgets ({});

	# connect to master daemon -----------------------------------
	return if not $self->connect_master;

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " Cluster Control");
	$win->signal_connect("destroy" => sub {
		$self->set_comp (cluster => undef);
		$self->rpc_server->disconnect if $self->rpc_server;
		Gtk->timeout_remove ($self->gtk_widgets->{timer})
			if $self->gtk_widgets->{timer};
		Gtk::Gdk->input_remove ($self->gtk_widgets->{log_input})
			if $self->gtk_widgets->{log_input};
		close $self->log_socket if $self->log_socket;
		if ( $self->exit_on_close ) {
			Gtk->exit ( 0 );
		}
	});
	$win->border_width(0);
	$win->set_uposition (10,10);
	$win->realize;

	# Register component and window ------------------------------
	$self->set_comp ( cluster => $self );
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);

	# Build dialog -----------------------------------------------
	my $dialog_vbox = Gtk::VBox->new;
	$dialog_vbox->show;
	$dialog_vbox->set_border_width(10);
	$win->add($dialog_vbox);

	my ($frame, $vbox, $hbox, $button, $clist, $sw);

	# Project Queue ----------------------------------------------
	$frame = Gtk::Frame->new ("Project Queue");
	$frame->show;
	$dialog_vbox->pack_start($frame, 0, 1, 0);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);
	$sw = new Gtk::ScrolledWindow( undef, undef );
	$vbox->pack_start ($sw, 0, 1, 0);
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );

	$clist = Gtk::CList->new_with_titles (
		"#",
		"Project", "State", "Progress"
	);
	$clist->show,
	$sw->add ($clist);
	$clist->set_usize (600, 100);
	$clist->set_column_width ( 0, 30 );
	$clist->set_column_width ( 1, 120 );
	$clist->set_column_width ( 2, 120 );
	$clist->set_selection_mode( 'browse' ); 
	$clist->signal_connect ("select_row", sub { $self->select_project (@_) } );

	$self->gtk_widgets->{project_clist} = $clist;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);
	
	$button = Gtk::Button->new_with_label (" Edit Project ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->edit_project } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Move Up ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->move_up_project } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Move Down ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->move_down_project } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Schedule Project ");
	$button->show;
	$button->signal_connect ("clicked", sub { $self->schedule_project } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Remove Project ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->remove_project } );
	$hbox->pack_start ($button, 0, 1, 0);

	# List of jobs ----------------------------------------------
	$frame = Gtk::Frame->new ("Jobs of the selected project");
	$frame->show;
	$dialog_vbox->pack_start($frame, 0, 1, 0);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);
	$sw = new Gtk::ScrolledWindow( undef, undef );
	$vbox->pack_start ($sw, 0, 1, 0);
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );
	$clist = Gtk::CList->new_with_titles (
		"#",
		"Info", "Dependencies", "State", "Progress"
	);
	$clist->show,
	$sw->add ($clist);
	$clist->set_usize (700, 200);
	$clist->set_column_width ( 0, 20 );
	$clist->set_column_width ( 1, 250 );
	$clist->set_column_width ( 2, 90 );
	$clist->set_column_width ( 3, 90 );
	$clist->set_selection_mode( 'browse' ); 
	$clist->signal_connect ("select_row", sub { $self->select_job (@_) } );

	$self->gtk_widgets->{job_clist} = $clist;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);
	
	$button = Gtk::Button->new_with_label (" Reset Job ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->reset_job } );
	$hbox->pack_start ($button, 0, 1, 0);

	# List of nodes ----------------------------------------------
	$frame = Gtk::Frame->new ("Registered Nodes");
	$frame->show;
	$dialog_vbox->pack_start($frame, 0, 1, 0);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);
	$sw = new Gtk::ScrolledWindow( undef, undef );
	$vbox->pack_start ($sw, 0, 1, 0);
	$sw->show;
	$sw->set_policy( 'automatic', 'automatic' );
	$clist = Gtk::CList->new_with_titles (
		"#",
		"Name", "Job", "Progress"
	);
	$clist->show,
	$sw->add ($clist);
	$clist->set_usize (600, 100);
	$clist->set_column_width ( 0, 20 );
	$clist->set_column_width ( 1, 80 );
	$clist->set_column_width ( 2, 350 );
	$clist->set_selection_mode( 'browse' ); 
	$clist->signal_connect ("select_row", sub { $self->select_node (@_) } );

	$self->gtk_widgets->{node_clist} = $clist;

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);
	
	$button = Gtk::Button->new_with_label (" Add Node ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->new_node } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Edit Node ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->edit_node } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Stop Node ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->stop_node } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Start Node ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->start_node } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Remove Node ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->remove_node } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label (" Shutdown Daemon ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->shutdown_daemon } );
	$hbox->pack_start ($button, 0, 1, 0);

	# Log info ---------------------------------------------------
	$frame = Gtk::Frame->new ("Log Output from Cluster Control Daemon");
	$frame->show;
	$dialog_vbox->pack_start($frame, 1, 1, 1);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);

	my $text_table = new Gtk::Table( 2, 2, 0 );
	$text_table->set_row_spacing( 0, 2 );
	$text_table->set_col_spacing( 0, 2 );
	$text_table->show();

	$vbox->pack_start($text_table, 1, 1, 1);

	my $text = new Gtk::Text( undef, undef );
	$text->show;
	$text->set_usize (undef,80);
	$text->set_editable( 0 );
	$text->set_word_wrap ( 1 );
	$text_table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );

	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$text_table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );
	$vscrollbar->show();

	$self->gtk_widgets->{log_text} = $text;

	$self->update_gui;

	$win->show;

	# Add Timeout for GUI update ---------------------------------
	$self->gtk_widgets->{timer} = Gtk->timeout_add (
		1000, sub { $self->update_gui }
	);

	return 1;
}

sub connect_master {
	my $self = shift;
	
	my $server = $self->config ('cluster_master_local') ?
			'localhost' : $self->config ('cluster_master_server');
	my $port = $self->config ('cluster_master_port');
	
	my $rpc_server = eval {
		Video::DVDRip::RPC::Client->connect (
			server   => $server,
			port     => $port,
			error_cb => sub { $self->client_server_error },
		)
	};
	
	if ( not $rpc_server ) {
		if ( not $self->config ('cluster_master_local') ) {
			$self->message_window (
				message => "Can't connect to master daemon on $server:$port."
			);
			return;
		}
		
		# Ok, we try to start a local master daemon
		system ("dvdrip-master 2 >/dev/null 2>&1 &");
		
		sleep 1;
		
		$rpc_server = eval {
			Video::DVDRip::RPC::Client->connect (
				server => $server,
				port   => $port,
				error_cb => sub { $self->client_server_error },
			)
		};
		
		# give up, if we still have no connection
		if ( not $rpc_server ) {
			croak "msg:\nCan't start local master daemon on port $port.\n".
			      "Execute the dvdrip-master program by hand to\n".
			      "see why it doesn't run.";
			return;
		}
	}
	
	# Ok, we have a connection
	$rpc_server->load_class (
		class => 'Video::DVDRip::Cluster::Master',
	);

	my $master = Video::DVDRip::Cluster::Master->get_master();
	$master->hello;

	$self->set_rpc_server ($rpc_server);
	$self->set_master ($master);

	my $sock = Video::DVDRip::RPC::Client->log_connect (
		server => $server,
		port   => $port + 10
	);

	$self->set_log_socket ( $sock );

	my $log_input =  Gtk::Gdk->input_add (
		$sock->fileno, 'read',
		sub {
			my $line = <$sock>;
			$self->gtk_widgets->{log_text}->insert (undef, undef, undef, $line);
		}
	);

	$self->gtk_widgets->{log_input} = $log_input;

	1;
}

sub client_server_error {
	my $self = shift;

	close $self->log_socket if $self->log_socket;

	$self->set_rpc_server(undef);
	$self->gtk_window_widget->destroy;

	return "msg: Cluster Control Daemon communication aborted.";
}

sub update_gui {
	my $self = shift;
	
	$self->update_project_list;
	$self->update_job_list;
	$self->update_node_list;
	
	1;
}

sub update_project_list {
	my $self = shift;

	my $master = $self->master;
	
	my ($clist, $rows);
	my $projects = $master->projects; 

	$clist = $self->gtk_widgets->{project_clist};
	$rows  = $self->gtk_widgets->{project_clist_rows};

	my $selected_project = $self->selected_project;

	my ($name, $state, $progress);

	my $nr = 0;
	my $select_row;

	while ( $nr < $rows and $nr < @{$projects} ) {
		($name, $state, $progress) = (
			$projects->[$nr]->label,
			$projects->[$nr]->state,
			$projects->[$nr]->progress,
		);
		$clist->set_text ($nr, 0, $nr+1)
			if $nr+1 != $clist->get_text ($nr, 0);
		$clist->set_text ($nr, 1, $name)
			if $name ne $clist->get_text ($nr, 1);
		$clist->set_text ($nr, 2, $state)
			if $state ne $clist->get_text ($nr, 2);
		$clist->set_text ($nr, 3, $progress)
			if $progress ne $clist->get_text ($nr, 3);

		$select_row = $nr if $selected_project and
				     $selected_project->id ==
				     $projects->[$nr]->id;

		++$nr;
	}
	
	while ( $nr < @{$projects} ) {
		$clist->append (
			$nr+1,
			$projects->[$nr]->label,
			$projects->[$nr]->state,
			$projects->[$nr]->progress,
		);
		$select_row = $nr if $selected_project and
				     $selected_project->id ==
				     $projects->[$nr]->id;
		++$nr;
	}

	$self->gtk_widgets->{project_clist_rows} = $nr;

	my $j = $rows-1;
	while ( $j >= $nr ) {
		$clist->remove ($j);
		--$j;
	}

	if ( $selected_project and $select_row != $self->selected_project_row ) {
		$clist->select_row ( $select_row, 0 );
	}

	1;
}

sub update_job_list {
	my $self = shift;

	my $master = $self->master;
	my $project = $self->selected_project;

	my $clist = $self->gtk_widgets->{job_clist};
	my $rows  = $self->gtk_widgets->{job_clist_rows};

# print "\njob list: project=$project\n";

	if ( not $project ) {
		$clist->clear;
		$self->gtk_widgets->{job_clist_rows} = 0;
		return;
	}

# print "job list: project->id = ".$project->id,"\n";

	my $project_id = $project->id;
	my $selected_job_id = $self->selected_job_id;

	my $jobs = $master->get_jobs_lref ( project_id => $project_id );

# print "job list: job cnt = ".@{$jobs}."\n";

	my ($id, $nr, $info, $dep, $state, $progress);

	my $i = 0;
	my $select_row;
	my @ids;
	while ( $i < $rows and $i < @{$jobs} ) {
		($id, $nr, $info, $dep, $state, $progress) = @{$jobs->[$i]}; 

# print "job list: row=$i updated job id = $id\n";

		push @ids, $id;

		$clist->set_text ($i, 0, $nr)
			if $nr != $clist->get_text ($i, 0);
		$clist->set_text ($i, 1, $info)
			if $info ne $clist->get_text ($i, 1);
		$clist->set_text ($i, 2, $dep)
			if $dep ne $clist->get_text ($i, 2);
		$clist->set_text ($i, 3, $state)
			if $state ne $clist->get_text ($i, 3);
		$clist->set_text ($i, 4, $progress)
			if $progress ne $clist->get_text ($i, 4);

		$select_row = $i if $selected_job_id == $id;

		++$i;
	}
	
	while ( $i < @{$jobs} ) {
		($id, $nr, $info, $dep, $state, $progress) = @{$jobs->[$i]}; 

		push @ids, $id;

# print "job list: row=$i appended job id = $id\n";

		$clist->append ( $nr, $info, $dep, $state, $progress );

		$select_row = $i if $selected_job_id == $id;

		++$i;
	}

	$self->gtk_widgets->{job_clist_rows} = $i;
	$self->gtk_widgets->{job_clist_ids}  = \@ids;

	my $j = $rows-1;
	while ( $j >= $i ) {

# print "job list: removing row = $j\n";

		$clist->remove ($j);
		--$j;
	}

	if ( $select_row != $self->selected_job_row ) {
		$clist->select_row ( $select_row, 0 );
	} else {
		$self->select_job ( undef, $select_row );
	}

	1;
}

sub update_node_list {
	my $self = shift;

	my $master = $self->master;
	
	my ($clist, $rows);
	my $nodes = $master->nodes;

	$clist = $self->gtk_widgets->{node_clist};
	$rows  = $self->gtk_widgets->{node_clist_rows};

	my $selected_node = $self->selected_node;

	my ($name, $project_name, $state, $progress);

	my $nr = 0;
	my $select_row;
	while ( $nr < $rows and $nr < @{$nodes} ) {
		($name, $state, $progress) = (
			$nodes->[$nr]->name,
			$nodes->[$nr]->job_info,
			$nodes->[$nr]->progress,
		);
		$clist->set_text ($nr, 0, $nr+1)
			if $nr+1 != $clist->get_text ($nr, 0);
		$clist->set_text ($nr, 1, $name)
			if $name ne $clist->get_text ($nr, 1);
		$clist->set_text ($nr, 2, $state)
			if $state ne $clist->get_text ($nr, 2);
		$clist->set_text ($nr, 3, $progress)
			if $progress ne $clist->get_text ($nr, 3);

		$select_row = $nr if $selected_node and
				     $selected_node->name eq
				     $nodes->[$nr]->name;

		++$nr;
	}
	
	while ( $nr < @{$nodes} ) {
		$clist->append (
			$nr+1,
			$nodes->[$nr]->name,
			$nodes->[$nr]->job_info,
			$nodes->[$nr]->progress,
		);

		$select_row = $nr if $selected_node and
				     $selected_node->name eq
				     $nodes->[$nr]->name;

		++$nr;
	}

	$self->gtk_widgets->{node_clist_rows} = $nr;

	my $j = $rows-1;
	while ( $j >= $nr ) {
		$clist->remove ($j);
		--$j;
	}

	if ( $select_row != $self->selected_node_row ) {
		$clist->select_row ( $select_row, 0 );
	} else {
		$self->select_node ( undef, $select_row );
	}

	1;
}

sub add_project {
	my $self = shift;
	my %par = @_;
	my ($project) = @par{'project'};
	
	my $cluster_project =
		Video::DVDRip::Cluster::Project->new (
			project => $project,
			title_nr => $project->selected_title_nr,
		);

	$self->master->add_project (
		project => $cluster_project,
	);
	
	$self->set_selected_project ( $cluster_project );
	$self->update_project_list;

#	$self->gtk_widgets->{project_clist}->select_row ( @{$self->master->projects} - 1, 0);

	$self->edit_project;

	1;
}

sub new_node {
	my $self = shift;
	
	Video::DVDRip::GUI::Cluster::Node->new (
		master     => $self->master,
		node       => Video::DVDRip::Cluster::Node->new,
		just_added => 1,
	)->open_window;

	1;
}

sub edit_node {
	my $self = shift;
	
	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state eq 'running';

	Video::DVDRip::GUI::Cluster::Node->new (
		master     => $self->master,
		node       => $node,
	)->open_window;

	1;
}

sub stop_node {
	my $self = shift;
	
	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state eq 'stopped';
	
	$node->stop;
	$self->update_node_list;

	1;
}

sub start_node {
	my $self = shift;
	
	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state ne 'stopped' and
		    $node->state ne 'aborted';
	
	$node->start;
	$self->update_node_list;

	1;
}

sub remove_node {
	my $self = shift;
	my %par = @_;
	my ($confirmed) = @par{'confirmed'};

	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state eq 'running';
	
	if ( not $confirmed ) {
		$self->confirm_window (
			message => "Do you want to remove the selected node?",
			yes_callback => sub { $self->remove_node ( confirmed => 1 ) },
		);
		return;
	}
	
	$self->master->remove_node ( node => $self->selected_node );
	
	$self->update_node_list;

	1;
}

sub select_job {
	my $self = shift;
	my ($widget, $row) = @_;

	$self->set_selected_job_row ($row);
	$self->set_selected_job_id ($self->gtk_widgets->{job_clist_ids}->[$row]);

	1;
}

sub select_node {
	my $self = shift;
	my ($widget, $row) = @_;

	$self->set_selected_node_row ($row);
	$self->set_selected_node ($self->master->nodes->[$row]);

	1;
}

sub move_up_project {
	my $self = shift;
	
	return if not $self->selected_project;

	$self->master->move_up_project ( project => $self->selected_project );
	$self->update_project_list;

	1;
}

sub move_down_project {
	my $self = shift;
	
	return if not $self->selected_project;

	$self->master->move_down_project ( project => $self->selected_project );
	$self->update_project_list;

	1;
}

sub schedule_project {
	my $self = shift;
	
	my $project = $self->selected_project;
	return if not $project;
	return if $project->state ne 'not scheduled';

	$self->master->schedule_project ( project => $project );
	$self->update_project_list;

	1;
}

sub select_project {
	my $self = shift;
	my ($widget, $row) = @_;

	$self->set_selected_project_row ($row);
	$self->set_selected_project ($self->master->projects->[$row]);

	$self->update_job_list;

	1;
}

sub remove_project {
	my $self = shift;
	
	my $project = $self->selected_project;
	return if not $project;

	$self->master->remove_project ( project => $project )
		or return;

	my $first_project = $self->master->projects->[0];

	if ( $first_project and $first_project->id != $project->id ) {
		$self->set_selected_project ($first_project);
		$self->set_selected_project_row(0);
	} else {
		$self->set_selected_project (undef);
		$self->set_selected_project_row(undef);
	}		

	$self->update_project_list;

	1;
}

sub edit_project {
	my $self = shift;
	
	my $project = $self->selected_project;
	return 1 if not $project;

	Video::DVDRip::GUI::Cluster::Title->new (
		master     => $self->master,
		title      => $project->title,
	)->open_window;

	1;
}

sub shutdown_daemon {
	my $self = shift;
	
	$self->confirm_window (
		message => "Do you really want to shutdown\nthe Cluster Control Daemon?",
		yes_callback => sub {
			$self->master->shutdown;
			$self->gtk_window_widget->destroy;
		},
	);

	1;
}

sub reset_job {
	my $self = shift;
	
	my $project = $self->selected_project;
	return 1 if not $project;

	my $job_id = $self->selected_job_id;
	return 1 if not $job_id;

	$project->reset_job ( job_id => $job_id );
	
	$self->update_job_list;

	1;
}

1;
