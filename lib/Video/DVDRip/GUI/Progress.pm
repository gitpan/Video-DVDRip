# $Id: Progress.pm,v 1.31 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Progress;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use strict;
use Carp;
use Data::Dumper;
use Cwd;

use POSIX qw(:errno_h);

sub cb_cancel			{ shift->{cb_cancel}			}
sub is_active			{ shift->{is_active}			}
sub progress_state		{ shift->{progress_state}		}
sub gtk_progress		{ shift->{gtk_progress}			}
sub gtk_cancel_button		{ shift->{gtk_cancel_button}		}
sub max_value			{ shift->{max_value}			}

sub set_cb_cancel		{ shift->{cb_cancel}		= $_[1]	}
sub set_is_active		{ shift->{is_active}		= $_[1]	}
sub set_progress_state		{ shift->{progress_state}	= $_[1]	}
sub set_gtk_progress		{ shift->{gtk_progress}		= $_[1]	}
sub set_gtk_cancel_button	{ shift->{gtk_cancel_button}	= $_[1]	}
sub set_max_value		{ shift->{max_value}		= $_[1]	}

sub build_factory {
	my $self = shift;
	
	$self->get_context->set_object ( "progress" => $self );

	my $progress = Gtk2::Ex::FormFactory::Form->new (
	    title   => __"Status",
	    object  => "project",
	    content => [
		Gtk2::Ex::FormFactory::HBox->new (
		    content => [
	        	Gtk2::Ex::FormFactory::ProgressBar->new (
			    name   => "progress",
			    attr   => "progress.progress_state",
			    expand => 1,
			),
	        	Gtk2::Ex::FormFactory::Button->new (
			    name     => "progress_cancel",
			    active   => 0,
			    label    => __"Cancel",
			    clicked_hook => sub {
			    	my $cb_cancel = $self->cb_cancel;
				&$cb_cancel() if $cb_cancel;
				1;
			    },
			),
		    ],
		),
	    ],
	);

	return $progress;
}

sub open {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($max_value, $label, $cb_cancel) =
	@par{'max_value','label','cb_cancel'};

	$self->set_gtk_progress (
		$self->get_form_factory
		     ->get_widget("progress")
		     ->get_gtk_widget,
	);

	$self->set_gtk_cancel_button (
		$self->get_form_factory
		     ->get_widget("progress_cancel")
		     ->get_gtk_widget,
	);

	$self->set_is_active ( 1 );
	$self->set_max_value($max_value);
	$self->set_cb_cancel ( $cb_cancel );

	$self->gtk_cancel_button->set_sensitive($cb_cancel?1:0);

	1;
}

sub update {
	my $self = shift;
	my %par = @_;
	my ($value, $label) = @par{'value','label'};

	$value = 0 if $value  < 0;
	$value = 1 if $value  > 1;

	$self->gtk_progress->set_text ($label);
	$self->gtk_progress->set_fraction ($value);

	1;
}

sub close {
	my $self = shift; $self->trace_in;

	$self->gtk_progress->set_fraction ( 0 );
	$self->gtk_cancel_button->set_sensitive(0);

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
	
	my $project = eval {$self->project };

	my $label;
	if ( $project ) {
		my $free = $project->get_free_diskspace;
		$label = __x("Free diskspace: {free} MB", free => $free);
	} else {
		$label = "";
	}

	$self->gtk_progress->set_text ($label);

	1;
}

1;
