# $Id: Node.pm,v 1.11 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Node;

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

use FileHandle;

sub multi_instance_window { 1 }

sub gtk_widgets			{ shift->{gtk_widgets}			}
sub set_gtk_widgets		{ shift->{gtk_widgets}		= $_[1] }

sub master			{ shift->{master}			}
sub set_master			{ shift->{master}		= $_[1] }

sub node			{ shift->{node}				}
sub set_node			{ shift->{node}			= $_[1] }

sub node_data			{ shift->{node_data}			}
sub set_node_data		{ shift->{node_data}		= $_[1] }

sub just_added			{ shift->{just_added}			}
sub set_just_added		{ shift->{just_added}		= $_[1] }

# GUI Stuff ----------------------------------------------------------

sub new {
	my $class = shift;
	my %par = @_;
	my  ($master, $just_added, $node) =
	@par{'master','just_added','node'};
	
	my $self = $class->SUPER::new (@_);

	$self->set_master ($master);
	$self->set_node ($node);
	$self->set_just_added ($just_added);
	$self->set_node_data ({
		name          => $node->name,
		hostname      => $node->hostname,
		is_master     => $node->is_master,
		data_is_local => $node->data_is_local,
		data_base_dir => $node->data_base_dir,
		username      => $node->username,
		tc_options    => $node->tc_options,
		ssh_cmd	      => $node->ssh_cmd,
	});

	return $self;
}

sub build {
	my $self = shift; $self->trace_in;

	# build window -----------------------------------------------
	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " Edit Cluster Node");
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

	# Edite Node Attributes --------------------------------------
	$frame = Gtk::Frame->new ("Edit Node Attributes");
	$frame->show;
	$dialog_vbox->pack_start($frame, 0, 1, 0);
	$vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	$frame->add ($vbox);

	my $node = $self->node;
	my $node_data = $self->node_data;

	my @fields = (
		{
			label => "Name",
			type => "string",
			value => $node->name,
			onchange => sub {
				$node_data->{name} = $_[0]->get_text;
			}
		},
		{
			label => "Hostname (defaults to Name)",
			type => "string",
			value => $node->hostname,
			onchange => sub {
				$node_data->{hostname} = $_[0]->get_text;
			}
		},
		{
			label => "NFS Mount Point / Local Dir of Data Base Directory",
			type => "string",
			value => $node->data_base_dir,
			onchange => sub {
				$node_data->{data_base_dir} = $_[0]->get_text;
			}
		},
		{
			label => "Special transcode options for this Node?",
			type => "string",
			value => $node->tc_options,
			onchange => sub {
				$node_data->{tc_options} = $_[0]->get_text;
			}
		},
		{
			label => "Does the Cluster Control Daemon run on this Node?",
			type => "switch",
			value => $node->is_master,
			onchange => sub {
				$node_data->{is_master} = $_[0];
			}
		},
		{
			label => "Is the dvd::rip data harddrive connected to this node?",
			type => "switch",
			value => $node->data_is_local,
			onchange => sub {
				$node_data->{data_is_local} = $_[0];
			}
		},
		{
			label => "Username to connect with ssh user key auth",
			type => "string",
			value => $node->username,
			onchange => sub {
				$node_data->{username} = $_[0]->get_text;
			}
		},
		{
			label => "SSH command and options (default is 'ssh -x')",
			type => "string",
			value => $node->ssh_cmd,
			onchange => sub {
				$node_data->{ssh_cmd} = $_[0]->get_text;
			}
		},
	);

	my $table = $self->create_dialog ( @fields );
	$vbox->pack_start ($table, 0, 1, 0);

	$hbox = Gtk::HBox->new;
	$hbox->show;
	$vbox->pack_start ($hbox, 0, 1, 0);

	$button = Gtk::Button->new_with_label ("      Ok      ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->dialog_ok } );
	$hbox->pack_start ($button, 0, 1, 0);

	$button = Gtk::Button->new_with_label ("     Test     ");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->test_node } );
	$hbox->pack_start ($button, 0, 1, 0);

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

	my $node = $self->node;

	$self->copy_dialog_to_node (
		node => $node
	);

	if ( $self->just_added ) {
		# we have to add this new node to the Master Daemon
		$self->master->add_node ( node => $node );

	} else {
		# otherwise just save the node itself
		$node->save;
	}

	$self->comp('cluster')->update_node_list;

	$self->gtk_window_widget->destroy;

	1;
}

sub copy_dialog_to_node {
	my $self = shift;
	my %par = @_;
	my ($node) = @par{'node'};
	
	# copy data into node object
	my ($k, $v);
	my $set_method;

	while ( ($k, $v) = each %{$self->node_data} ) {
		$set_method = "set_".$k;
		$node->$set_method ($v);
	}
	
	1;
}

sub dialog_cancel {
	my $self = shift;
	
	$self->gtk_window_widget->destroy;
	
	1;
}

sub test_node {
	my $self = shift;
	
	# touch a test file in the base project dir
	# (we'll later check if this file appears also
	#  on the node)
	my $base_project_dir = $self->config('base_project_dir');
	my $test_file = "$base_project_dir/dvdrip-test-$$-".time;
	my $fh = FileHandle->new;
	open ($fh, ">$test_file") or croak "can't write $test_file";
	close $fh;

	# run tests on the node, making a copy, set the data
	# from the dialog and work on this copy
	my $node = $self->node->clone;
	$self->copy_dialog_to_node ( node => $node );
	
	# trigger test start
	$node->run_tests;

	# open a window and add a timeout for
	# polling the result
	my $text_widget = $self->long_message_window (
		message => "Waiting on the test result...\n\n"
	);

	Gtk->timeout_add ( 200, sub {
		return 1 if not $node->test_finished;
		$self->test_node_show_result (
			test_file   => $test_file,
			node        => $node,
			text_widget => $text_widget,
		);
		return 0;
	});

	1;
}

sub test_node_show_result {
	my $self = shift;
	my %par = @_;
	my  ($node, $test_file, $text_widget) =
	@par{'node','test_file','text_widget'};

	my $result = $node->test_result;

	#---------------------------------------------------------------
	# $result is a scalar containing a fatal error message, or
	# a hash reference with the following keys:
	#
	#   data_base_dir_content   sorted content of the data_base_dir,
	#			    or error message
	#   write_test		    SUCCESS if write was succesfull,
	#			    or error message otherwise
	#   transcode_version       full output of transcode -h
	#---------------------------------------------------------------
	
	if ( not ref $result ) {
		$text_widget->insert (
			undef, undef, undef, "Can't execute tests:\n\n$result"
		);
		unlink $test_file;
		return 1;
	}
	
	# now execute the test command on this machine
	my $base_project_dir = $self->config('base_project_dir');
	my $local_command = $node->get_test_command (
		data_base_dir => $base_project_dir
	);

	my $local_output = qx[ ($local_command) 2>&1 ];

	my $local_result = $node->parse_test_output (
		output => $local_output
	);

	# remove test file
	unlink $test_file;

	# check if results are equal
	my $report;
	my $details;

	my %desc = (
		ssh_connect		=> "ssh connect",
		data_base_dir_content 	=> "Content of project base directory",
		write_test		=> "Project base directory writable",
		transcode_version	=> "transcode version match",
	);

	foreach my $case ( qw ( ssh_connect data_base_dir_content write_test transcode_version ) ) {
		$report .= "Test case : $desc{$case}\n";
		$report .= "Result    : ";

		if ( $result->{$case} eq $local_result->{$case} ) {
			$report  .= "Ok\n\n";
		} else {
			$report  .= "Not Ok!\n\n";
			$details .= "Test case    : $desc{$case}\n";
			if ( $case eq 'ssh_connect' ) {
				$details .= "Node output  :\n$result->{output}\n\n";
				last;
			} else {
				$details .= "Node output  :\n$result->{$case}\n\n";
			}
			$details .= "Local output :\n$local_result->{$case}\n\n";
		}
	}
	
	$text_widget->insert (undef, undef, undef, "All tests successful!\n\n")
		if not $details;

	$text_widget->insert (undef, undef, undef, "Brief report:\n\n".$report);

	if ( $details ) {
		if ( $result->{output_rest} =~ /\S/ ) {
			$details .= "Unrecognized output :\n$result->{output_rest}\n\n";
		}
		$text_widget->insert (
			undef, undef, undef,
			"\nDetailed report:\n\n".$details
		);
	}

	1;
}

1;
