# $Id: Control.pm,v 1.24 2005/08/01 19:12:43 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Control;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Base;

use Event::RPC::Client;
use Video::DVDRip::GUI::Cluster::Node;
use Video::DVDRip::GUI::Cluster::Title;

use strict;
use Carp;

sub rpc_server			{ shift->{rpc_server}			}
sub set_rpc_server		{ shift->{rpc_server}		= $_[1] }

sub master			{ shift->{master}			}
sub set_master			{ shift->{master}		= $_[1] }

sub log_socket			{ shift->{log_socket}			}
sub set_log_socket		{ shift->{log_socket}		= $_[1] }

sub gtk_log_view		{ shift->{gtk_log_view}			}
sub set_gtk_log_view		{ shift->{gtk_log_view}		= $_[1]	}

sub gtk_log_buffer		{ shift->{gtk_log_buffer}		}
sub set_gtk_log_buffer		{ shift->{gtk_log_buffer}	= $_[1]	}

sub exit_on_close		{ shift->{exit_on_close}		}
sub set_exit_on_close		{ shift->{exit_on_close}	= $_[1] }

sub selected_project_id		{ shift->{selected_project_id}		}
sub selected_job_id		{ shift->{selected_job_id}		}
sub selected_node_name		{ shift->{selected_node_name}		}

sub set_selected_project_id	{ shift->{selected_project_id}	= $_[1]	}
sub set_selected_job_id		{ shift->{selected_job_id}	= $_[1]	}
sub set_selected_node_name	{ shift->{selected_node_name}	= $_[1]	}

sub master_event_queue		{ shift->{master_event_queue}		}
sub set_master_event_queue	{ shift->{master_event_queue}	= $_[1]	}

sub log_watcher			{ shift->{log_watcher}			}
sub event_timeout		{ shift->{event_timeout}		}

sub set_log_watcher		{ shift->{log_watcher}		= $_[1]	}
sub set_event_timeout		{ shift->{event_timeout}	= $_[1]	}

sub node_gui			{ shift->{node_gui}			}
sub set_node_gui		{ shift->{node_gui}		= $_[1]	}

sub selected_node {
	my $self = shift;
	my $name = $self->selected_node_name;
	return unless defined $name;
	$name = $name->[0];
	return $self->master->get_node_by_name($name);
}

sub selected_project {
	my $self = shift;
	my $id = $self->selected_project_id;
	return unless defined $id;
	$id = $id->[0];
	return unless defined $id;
	return $self->master->get_project_by_id($id);
}

sub selected_job {
	my $self = shift;
	my $id = $self->selected_job_id;
	return unless defined $id;
	$id = $id->[0];
	return unless defined $id;
	return $self->selected_project->get_job_by_id($id);
}

# GUI Stuff ----------------------------------------------------------

my $cluster_ff;

sub open_window {
	my $self = shift;
	
	return if $cluster_ff;
	return if not $self->connect_master;

	my $context = $self->get_context;
	
	$context->set_object ( cluster_gui => $self );
	
	$cluster_ff = Gtk2::Ex::FormFactory->new (
	    context   => $context,
	    parent_ff => $self->get_form_factory,
            sync      => 1,
	    content   => [
		Gtk2::Ex::FormFactory::Window->new (
		    title => __"dvd::rip - Cluster Control",
		    customize_hook => sub {
			my ($gtk_window) = @_;
			$_[0]->parent->set(
		          default_width  => 760,
		          default_height => 700,
			);
			1;
		    },
		    closed_hook => sub {
		        $self->close_window;
		    },
		    content => [
		        $self->build_projects_box,
			$self->build_jobs_box,
			$self->build_nodes_box,
			$self->build_log_box,
		    ],
		),
	    ],
	);
	
	$self->set_form_factory ($cluster_ff);
	
	$cluster_ff->build;
	$cluster_ff->update;
	$cluster_ff->show;

	1;
}

sub close_window {
	my $self = shift;

	Gtk2::Helper->remove_watch($self->log_watcher);
	Glib::Source->remove($self->event_timeout);

        $cluster_ff->close;
        $cluster_ff = undef;

	$self->rpc_server->disconnect;
	
	Gtk2->main_quit if $self->exit_on_close;

	1;
}

sub build_projects_box {
	my $self = shift;

	Gtk2::SimpleList->add_column_type(
		'cluster_project_text',
		type	 => "Glib::Scalar",
		renderer => "Gtk2::CellRendererText",
		attr     => sub {
		    my ($treecol, $cell, $model, $iter, $col_num) = @_;
		    my $text  = $model->get($iter, $col_num);
		    my $state = $model->get($iter, 3);
		    my $run   = $state eq 'running';
		    $cell->set ( text       => $text );
		    $cell->set ( weight     => $run ? 700 : 500);
		    1;
		},
	);

	return Gtk2::Ex::FormFactory::VBox->new (
	    title   => __"Project queue",
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    attr               => "cluster.projects_list",
		    attr_select	       => "cluster_gui.selected_project_id",
		    attr_select_column => 0,
		    height             => 100,
		    scrollbars         => [ "automatic", "automatic" ],
		    columns            => [
		    	"id",
			__"Number",   __"Project", __"State",
			__"Progress",
		    ],
		    types	   => [
	    		 "int", ("cluster_project_text") x 4
		    ],
		    selection_mode => "single",
		    customize_hook => sub {
	        	my ($gtk_simple_list) = @_;
			($gtk_simple_list->get_columns)[0]->set ( visible => 0 );
			1;
		    },
		),
		Gtk2::Ex::FormFactory::HBox->new (
		    content => [
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Edit project",
			    stock => "gtk-edit",
			    clicked_hook => sub { $self->edit_project },
			    active_cond => sub {
			        my $project = $self->selected_project or return;
				$project->state eq 'not scheduled';
			    },
			    active_depends => "cluster_project",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Move up",
			    stock => "gtk-go-up",
			    clicked_hook => sub { $self->move_up_project },
			    active_cond => sub {
			        my $project = $self->selected_project or return;
				$project->state eq 'not scheduled';
			    },
			    active_depends => "cluster_project",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Move down",
			    stock => "gtk-go-down",
			    clicked_hook => sub { $self->move_down_project },
			    active_cond => sub {
			        my $project = $self->selected_project or return;
				$project->state eq 'not scheduled';
			    },
			    active_depends => "cluster_project",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Schedule project",
			    stock => "gtk-execute",
			    clicked_hook => sub { $self->schedule_project },
			    active_cond => sub {
			        my $project = $self->selected_project or return;
				$project->state eq 'not scheduled';
			    },
			    active_depends => "cluster_project",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Remove project",
			    stock => "gtk-delete",
			    clicked_hook => sub { $self->remove_project },
			    active_cond => sub {
			        my $project = $self->selected_project or return;
				$project->state ne 'running';
			    },
			    active_depends => "cluster_project",
			),
		    ],
		),
	    ],
	);
}

sub build_jobs_box {
	my $self = shift;
	
	Gtk2::SimpleList->add_column_type(
		'cluster_job_text',
		type	 => "Glib::Scalar",
		renderer => "Gtk2::CellRendererText",
		attr     => sub {
		    my ($treecol, $cell, $model, $iter, $col_num) = @_;
		    my $text  = $model->get($iter, $col_num);
		    my $state = $model->get($iter, 4);
		    my $run   = $state eq 'running';
		    $cell->set ( text       => $text );
		    $cell->set ( foreground => $state eq 'aborted' ? "#ff0000" : "#000000" );
		    $cell->set ( weight     => $run ? 700 : 500);
		    1;
		},
	);

	return Gtk2::Ex::FormFactory::VBox->new (
	    title   => __"Jobs of the selected project",
	    expand  => 1,
	    object  => "cluster_project",
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    attr               => "cluster_gui.jobs_list",
		    attr_select        => "cluster_gui.selected_job_id",
		    attr_select_column => 0,
		    expand             => 1,
		    scrollbars         => [ "automatic", "automatic" ],
		    columns            => [
		    	"id",
			__"Number",   __"Info", __"Dependencies",
			__"State",    __"Progress"
		    ],
		    types	   => [
	    		 "int", ("cluster_job_text") x 5
		    ],
		    selection_mode => "single",
		    customize_hook => sub {
	        	my ($gtk_simple_list) = @_;
			($gtk_simple_list->get_columns)[0]->set ( visible => 0 );
			1;
		    },
		),
		Gtk2::Ex::FormFactory::HBox->new (
		    content => [
		        Gtk2::Ex::FormFactory::Button->new (
			    object => "cluster_job",
			    label  => __"Reset job",
			    stock  => "gtk-cancel",
			    clicked_hook => sub { $self->reset_job },
			),
		    ],
		),
	    ],
	);
}

sub jobs_list {
	my $self = shift;
	my $project = $self->selected_project or return;
	return $project->jobs_list;
}

sub build_nodes_box {
	my $self = shift;
	
	Gtk2::SimpleList->add_column_type(
		'cluster_node_text',
		type	 => "Glib::Scalar",
		renderer => "Gtk2::CellRendererText",
		attr     => sub {
		    my ($treecol, $cell, $model, $iter, $col_num) = @_;
		    my $text  = $model->get($iter, $col_num);
		    my $state = $model->get($iter, 4);
		    my $run   = $state !~ /stopped|idle|offline/;
		    $cell->set ( text       => $text );
		    $cell->set ( weight     => $run ? 700 : 500);
		    1;
		},
	);

	return Gtk2::Ex::FormFactory::VBox->new (
	    title   => __"Registered Nodes",
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    attr               => "cluster.nodes_list",
		    attr_select	       => "cluster_gui.selected_node_name",
		    attr_select_column => 0,
		    expand             => 1,
		    height             => 100,
		    scrollbars         => [ "automatic", "automatic" ],
		    columns            => [
		    	"name",
			__"Number",   __"Name", __"Job",
			__"Progress"
		    ],
#		    types	   => [
#	    		 "int", ("cluster_node_text") x 4
#		    ],
		    selection_mode => "single",
		    customize_hook => sub {
	        	my ($gtk_simple_list) = @_;
			($gtk_simple_list->get_columns)[0]->set ( visible => 0 );
			1;
		    },
		),
		Gtk2::Ex::FormFactory::HBox->new (
		    content => [
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Add node",
			    stock => "gtk-add",
			    clicked_hook => sub { $self->add_node },
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    object => "cluster_node",
			    label  => __"Edit node",
			    stock  => "gtk-edit",
			    clicked_hook => sub { $self->edit_node },
			    active_cond => sub {
			        my $node = $self->selected_node or return;
				my $state = $node->state;
				$node->state ne 'running';
			    },
			    active_depends => "cluster_node",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    object => "cluster_node",
			    label => __"Start node",
			    stock => "gtk-execute",
			    clicked_hook => sub { $self->start_node },
			    active_cond => sub {
			        my $node = $self->selected_node or return;
				$node->state eq 'stopped';
			    },
			    active_depends => "cluster_node",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    object => "cluster_node",
			    label => __"Stop node",
			    stock => "gtk-cancel",
			    clicked_hook => sub { $self->stop_node },
			    active_cond => sub {
			        my $node = $self->selected_node or return;
				$node->state ne 'stopped';
			    },
			    active_depends => "cluster_node",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    object => "cluster_node",
			    label => __"Remove node",
			    stock => "gtk-delete",
			    clicked_hook => sub { $self->remove_node },
			    active_cond => sub {
			        my $node = $self->selected_node or return;
				my $state = $node->state;
				$node->state ne 'running';
			    },
			    active_depends => "cluster_node",
			),
		        Gtk2::Ex::FormFactory::Button->new (
			    label => __"Shutdown daemon",
			    stock => "gtk-quit",
			    clicked_hook => sub { $self->shutdown_daemon },
			),
		    ],
		),
	    ],
	);
}

sub build_log_box {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::VBox->new (
	    title   => __"Cluster control daemon log output",
	    height  => 80,
	    content => [
	        Gtk2::Ex::FormFactory::TextView->new (
		    scrollbars => [ "never", "always" ],
		    expand     => 1,
		    properties => {
			editable       => 0,
			cursor_visible => 0,
			wrap_mode      => "word",
		    },
		    customize_hook => sub {
			my ($gtk_text_view) = @_;
			my $font = Gtk2::Pango::FontDescription->from_string("mono 7.2");
			$gtk_text_view->modify_font ($font);
			my $tag_table = Gtk2::TextTagTable->new;
			$tag_table->add ( $self->create_text_tag ( "date",
				foreground => "#666666",
			));
			my $buffer = Gtk2::TextBuffer->new ( $tag_table );
			$gtk_text_view->set_buffer($buffer);
			$self->set_gtk_log_buffer($buffer);
			$self->set_gtk_log_view($gtk_text_view);
			1;
		    },
		),
	    ],
	);
}

sub connect_master {
	my $self = shift;
	
	my $server = $self->config ('cluster_master_local') ?
			'localhost' : $self->config ('cluster_master_server');
	my $port = $self->config ('cluster_master_port');
	
	my $rpc_server = Event::RPC::Client->new (
		host   => $server,
		port   => $port,
		error_cb => sub { $self->client_server_error },
	);

	eval { $rpc_server->connect };

	if ( not $rpc_server->get_connected ) {
		if ( not $self->config ('cluster_master_local') ) {
			$self->message_window (
				message => __x("Can't connect to master daemon on {server}:{port}.", server => $server, port => $port)
			);
			return;
		}
		
		# Ok, we try to start a local master daemon
		system ("dvdrip-master 2 >/dev/null 2>&1 &");
		
		sleep 1;
		
		eval { $rpc_server->connect };
		
		# give up, if we still have no connection
		if ( not $rpc_server->get_connected ) {
			croak "msg:\nCan't start local master daemon on port $port.\n".
			      "Execute the dvdrip-master program by hand to\n".
			      "see why it doesn't run.";
			return;
		}
	}
	
	my $master = Video::DVDRip::Cluster::Master->get_master();
	$master->hello;

	$self->set_rpc_server ($rpc_server);
	$self->set_master ($master);
	$self->get_context->set_object ( cluster => $master );

	my $sock = Event::RPC::Client->log_connect (
		server => $server,
		port   => $port + 1,
	);

	$self->set_log_socket ( $sock );

	$self->set_master_event_queue([]);

	my $log_watcher = Gtk2::Helper->add_watch (
	    $sock->fileno, 'in',
	    sub {
		my $data;
		if ( !sysread($sock, $data, 4096) ) {
		    $self->close_window;
		    return 1;
		}
		while ( $data =~ /^(.*)$/mg ) {
		    my $line = $1;
		    if ( $line =~ /EVENT\t(.*)/ ) {
			$self->enqueue_master_event(split("\t", $1));
		    } else {
			my $buffer = $self->gtk_log_buffer;
			$buffer->insert($buffer->get_end_iter, $line."\n");
			my $text_view = $self->gtk_log_view;
			Glib::Idle->add (sub{
				my $iter = $buffer->get_end_iter;
				$text_view->scroll_to_iter($iter,0.0, 0, 0.0, 0.0);
				0;
			});
		    }
		}
		1;
	    }
	);

	my $event_timeout = Glib::Timeout->add (200, sub {
		$self->process_master_event_queue;
		1;
	});

	$self->set_log_watcher($log_watcher);
	$self->set_event_timeout($event_timeout);

	1;
}

sub enqueue_master_event {
	my $self = shift;
	my ($event, @args) = @_;
# print "MASTER-EVENT: $event\n";
	my $queue = $self->master_event_queue;
	push @{$queue}, [ $event, \@args ];
	
	return;
}

{
    my %event2action = (
        PROJECT_UPDATE       => "update_projects_list",
	PROJECT_LIST_UPDATE  => "update_projects_list",
	PROJECT_DELETED      => "update_projects_list",
	JOB_PLAN_UPDATE      => "update_jobs_list[ARG0]",
	JOB_UPDATE           => "update_job[ARG0,ARG1]",
	NODE_UPDATE          => "update_nodes_list",
	NODE_DELETED         => "update_nodes_list",
	JOB_PROGRESS_UPDATE  => "update_job_progress[ARG0,ARG1,ARG2,ARG3]",
	NODE_PROGRESS_UPDATE => "update_node_progress[ARG0,ARG1,ARG2]",
	NODE_TEST_FINISHED   => "node_test_finished",
	NO_MASTER_NODE_FOUND => "no_master_node_found",
    );

    sub process_master_event_queue {
	my $self = shift;
	my $queue = $self->master_event_queue;

	return if @{$queue} == 0;

	my %actions_seen;
	my @actions;
	for ( my $i=@{$queue}-1; $i >= 0; --$i ) {
		my $action = $event2action{$queue->[$i]->[0]};
		if ( !$action ) {
		    warn "Unknown master event $queue->[$i]->[0]";
		    next;
		}
		if ( $action =~ /ARG/ ) {
			$action =~ s/ARG0/$queue->[$i]->[1]->[0]/;
			$action =~ s/ARG1/$queue->[$i]->[1]->[1]/;
			$action =~ s/ARG2/$queue->[$i]->[1]->[2]/;
			$action =~ s/ARG3/$queue->[$i]->[1]->[3]/;
		}
		next if $actions_seen{$action};
		$actions_seen{$action} = 1;
		unshift @actions, [ $action, $queue->[$i] ];
	}

# print "Queue items: ".@{$queue}." => actions ".@actions."\n";

	@{$queue} = ();
	
	my $context = $self->get_context;

	my $job_slist = $self->get_form_factory
			     ->get_widget("cluster_gui.jobs_list")
			     ->get_gtk_widget;

	my $node_slist = $self->get_form_factory
			     ->get_widget("cluster.nodes_list")
			     ->get_gtk_widget;

	foreach my $action_item ( @actions ) {
		my $action = $action_item->[0];
		my $event  = $action_item->[1]->[0];
		my $args   = $action_item->[1]->[1];

		if ( $action eq 'update_projects_list' ) {
			$context->update_object_attr_widgets("cluster.projects_list");

		} elsif ( $action =~ /^update_jobs_list/ ) {
			my ($project_id) = @{$args};
			next unless $self->selected_project_id;
# print "update_jobs_list: $project_id <> ".$self->selected_project_id->[0]."\n";
			$context->update_object_attr_widgets("cluster_gui.jobs_list")
				if $project_id == $self->selected_project_id->[0];

		} elsif ( $action =~ /^update_job_progress/ ) {
			next unless $self->selected_project_id;
			my ($project_id, $job_nr, $state, $progress) = @{$args};
			next if $project_id != $self->selected_project_id->[0];
			$job_slist->{data}->[$job_nr-1]->[4] = $state;
			$job_slist->{data}->[$job_nr-1]->[5] = $progress;

		} elsif ( $action =~ /^update_node_progress/ ) {
			my ($name, $job, $progress) = @{$args};
			for (my $i=0; $i < @{$node_slist->{data}}; ++$i ) {
			  if ( $node_slist->{data}->[$i]->[0] eq $name ) {
			    $node_slist->{data}->[$i]->[3] = $job;
			    $node_slist->{data}->[$i]->[4] = $progress;
			    last;
			  }
			}

		} elsif ( $action =~ /^update_job/ ) {
warn "TODO: update_job\n";
			my ($job_id, $project_id) = @{$args};
			$context->update_object_attr_widgets("cluster.jobs_list")
				if $project_id == $self->selected_project_id->[0];

		} elsif ( $action eq 'update_nodes_list' ) {
			$context->update_object_attr_widgets("cluster.nodes_list");
			$context->update_object_attr_widgets("cluster_node");

		} elsif ( $action eq 'no_master_node_found' ) {
			$self->error_window (
			    message => __"Please configure the master node first",
			);

		} elsif ( $action eq 'node_test_finished' ) {
			my $node_gui = $self->node_gui;
			$node_gui->node_test_finished if $node_gui;
		}
	}
	
	1;
    }
}

sub client_server_error {
	my $self = shift;

	$self->close_window;

	die "msg: Cluster Control Daemon communication aborted.";
}

sub add_project {
	my $self = shift;
	my %par = @_;
	my ($project, $title) = @par{'project','title'};

	my $cluster_project =
		Video::DVDRip::Cluster::Project->new (
			project  => $project,
			title_nr => $title->nr,
		);

	$self->master->add_project (
		project => $cluster_project,
	);
	
	$self->edit_project (
		project => $cluster_project,
	);

	1;
}

sub edit_project {
	my $self = shift;
	my %par = @_;
	my ($project) = @par{'project'};

	$project ||= $self->selected_project;
	return 1 if not $project;

	Video::DVDRip::GUI::Cluster::Title->new (
		cluster_ff => $cluster_ff,
		master     => $self->master,
		title      => $project->title,
	)->open_window;

	1;
}

sub remove_project {
	my $self = shift;

	my $project = $self->selected_project;
	return if not $project;

	$self->confirm_window (
		message => __"Do you want to remove the selected project?",
		yes_callback => sub {
			$self->master->remove_project ( project => $project )
		},
	);

	1;
}

sub add_node {
	my $self = shift;
	
	my $node_gui = Video::DVDRip::GUI::Cluster::Node->new (
		cluster_ff => $cluster_ff,
		master     => $self->master,
		node       => Video::DVDRip::Cluster::Node->new,
		just_added => 1,
	);

	$node_gui->open_window;
	
	$self->set_node_gui($node_gui);

	1;
}

sub edit_node {
	my $self = shift;
	
	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state eq 'running';

	my $node_gui = Video::DVDRip::GUI::Cluster::Node->new (
		cluster_ff => $cluster_ff,
		master     => $self->master,
		node       => $node,
	);

	$node_gui->open_window;
	
	$self->set_node_gui($node_gui);

	1;
}

sub stop_node {
	my $self = shift;
	
	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state eq 'stopped';
	
	$node->stop;

	1;
}

sub start_node {
	my $self = shift;
	
	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state ne 'stopped' and
		    $node->state ne 'aborted';
	
	$node->start;

	1;
}

sub remove_node {
	my $self = shift;

	my $node = $self->selected_node;
	return 1 if not $node;
	return 1 if $node->state eq 'running';
	
	$self->confirm_window (
		message => __"Do you want to remove the selected node?",
		yes_callback => sub {
			$self->master->remove_node (
				node => $self->selected_node
			);
		},
	);
	
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

	1;
}

sub move_down_project {
	my $self = shift;
	
	return if not $self->selected_project;

	$self->master->move_down_project ( project => $self->selected_project );

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

sub shutdown_daemon {
	my $self = shift;
	
	$self->confirm_window (
		message => __"Do you really want to shutdown\nthe Cluster Control Daemon?",
		yes_callback => sub {
			$self->master->shutdown;
			$self->get_form_factory->close;
			Gtk2->main_quit;
			1;
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
	$job_id = $job_id->[0];
	return 1 if not $job_id;

	$project->reset_job ( job_id => $job_id );

	1;
}

1;
