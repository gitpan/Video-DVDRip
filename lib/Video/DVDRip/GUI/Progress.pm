# $Id: Progress.pm,v 1.23 2002/10/15 21:09:34 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Progress;

use base Video::DVDRip::GUI::Component;

use strict;
use Carp;
use Data::Dumper;
use Cwd;

use POSIX qw(:errno_h);

sub gtk_progress		{ shift->{gtk_progress}			}
sub gtk_cancel_button		{ shift->{gtk_cancel_button}		}
sub cb_cancel			{ shift->{cb_cancel}			}
sub is_active			{ shift->{is_active}			}

sub set_gtk_cancel_button	{ shift->{gtk_cancel_button}	= $_[1] }
sub set_gtk_progress		{ shift->{gtk_progress}		= $_[1] }
sub set_cb_cancel		{ shift->{cb_cancel}		= $_[1]	}
sub set_is_active		{ shift->{is_active}		= $_[1]	}

sub build {
	my $self = shift; $self->trace_in;

	my $hbox = Gtk::HBox->new;
	$hbox->show;

	my $progress = Gtk::ProgressBar->new;
	$progress->show;
	$progress->set_value(0);
	$progress->set_format_string ("");
	$progress->set_show_text (1);
	$hbox->pack_start($progress, 1, 1, 0);

	my $button = Gtk::Button->new_with_label (" Cancel ");
	$button->signal_connect ("clicked", sub { $self->cancel } );

	$hbox->pack_start($button, 0, 1, 0);

	$self->set_widget ($hbox);
	$self->set_gtk_progress ($progress);
	$self->set_gtk_cancel_button ($button);
	$self->set_comp ( progress => $self );

	$self->set_is_active (0);
	$self->set_idle_label;

	return $hbox;
}

sub open {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($max_value, $label, $cb_cancel) =
	@par{'max_value','label','cb_cancel'};

	$self->set_is_active ( 1 );
	
	my $adj = Gtk::Adjustment->new ( 0, 0, $max_value, 0, 0, 0); 

	my $progress = $self->gtk_progress;
	$progress->set_adjustment($adj);
	$progress->set_format_string ($label);
	$progress->set_show_text (1);
	$progress->set_value(1);

	$self->set_cb_cancel ( $cb_cancel );

	$self->gtk_cancel_button->show if $cb_cancel;
	$self->gtk_cancel_button->hide if not $cb_cancel;

	1;
}

sub update {
	my $self = shift;
	my %par = @_;
	my ($value, $label) = @par{'value','label'};

	$label =~ s/%/%%/g;

	$self->gtk_progress->set_format_string ($label);
	$self->gtk_progress->set_value($value) if $value > 0;

	1;
}

sub close {
	my $self = shift; $self->trace_in;

	$self->gtk_progress->set_value ( 0 );
	$self->gtk_cancel_button->hide;

	$self->set_is_active( 0 );
	$self->set_idle_label;

	1;
}

sub cancel {
	my $self = shift; $self->trace_in;

	my $cb_cancel = $self->cb_cancel;

	&$cb_cancel() if $cb_cancel;
	
	$self->close;

	1;
}

sub set_idle_label {
	my $self = shift; $self->trace_in;
	
	my $title;
	my $project = eval {$self->comp('project')};
	$title = $project->selected_title if $project;

	my $label;
	if ( $title ) {
		my $dir  = $title->avi_dir;
		my $free = $title->get_free_diskspace;
		$label = "Free diskspace: $free MB";
	} else {
		$label = "";
	}

	$self->gtk_progress->set_format_string ($label);
	
	1;
}

1;
