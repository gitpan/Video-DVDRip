# $Id: StorageTab.pm,v 1.6 2001/12/15 14:37:12 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project;

use Carp;
use strict;

#------------------------------------------------------------------------
# Build Storage Tab
#------------------------------------------------------------------------

sub create_storage_tab {
	my $self = shift; $self->trace_in;

	my $vbox = Gtk::VBox->new;
	$vbox->set_border_width(5);
	$vbox->show;
	
	my $frame = Gtk::Frame->new ("Storage path information");
	$frame->show;

	my $hbox = Gtk::HBox->new;
	$hbox->set_border_width(5);
	$hbox->show;

	my ($dialog, $widgets) = $self->create_dialog (
		{ label => "Project Name",
		  value => $self->project->name,
		  type  => 'text'
		},
		{ label => "VOB Directory",
		  value => $self->project->vob_dir,
		  type  => 'text',
		  onchange => sub {
		  	$self->project->set_vob_dir (shift->get_text)
		  },
		},
		{ label => "AVI Directory",
		  value => $self->project->avi_dir,
		  type  => 'text',
		  onchange => sub {
		  	$self->project->set_avi_dir (shift->get_text)
		  },
		},
		{ label => "Temp Directory",
		  value => $self->project->snap_dir,
		  type  => 'text',
		  onchange => sub {
		  	$self->project->set_snap_dir (shift->get_text)
		  },
		},
	);

	# changes of project name should also change
	# vob- and avi-dir, if they are not touched yet
	$widgets->[0]->signal_connect ("changed", sub {
		if ( $widgets->[0]->get_text =~ /\s/ ) {
			# spaces in project name not allowed
			$widgets->[0]->set_text ( $self->project->name );
			return 1;
		}
		if ( $widgets->[1]->get_text eq
		     $self->config('base_project_dir')."/".
		     $self->project->name."/vob" ) {
			$self->project->set_vob_dir (
				$self->config('base_project_dir')."/".
				$widgets->[0]->get_text."/vob"
			);
			$widgets->[1]->set_text ( $self->project->vob_dir );
		}
		if ( $widgets->[2]->get_text eq
		     $self->config('base_project_dir')."/".
		     $self->project->name."/avi" ) {
			$self->project->set_avi_dir (
				$self->config('base_project_dir')."/".
				$widgets->[0]->get_text."/avi"
			);
			$widgets->[2]->set_text ( $self->project->avi_dir );
		}
		if ( $widgets->[3]->get_text eq
		     $self->config('base_project_dir')."/".
		     $self->project->name."/tmp" ) {
			$self->project->set_snap_dir (
				$self->config('base_project_dir')."/".
				$widgets->[0]->get_text."/tmp"
			);
			$widgets->[3]->set_text ( $self->project->snap_dir );
		}
		$self->project->set_name ($widgets->[0]->get_text);
		$self->comp('main')->widget->set_title (
			$self->config('program_name')." - ".$self->project->name
		);
	});

	$hbox->pack_start ( $dialog, 0, 1, 0);
	$frame->add ($hbox);
	$vbox->pack_start ( $frame, 0, 1, 0);

	return $vbox;
}

1;
