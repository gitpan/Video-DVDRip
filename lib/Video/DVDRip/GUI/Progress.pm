# $Id: Progress.pm,v 1.9 2001/12/15 00:15:52 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
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

sub gtk_idle			{ shift->{gtk_idle}			}
sub gtk_progress		{ shift->{gtk_progress}			}
sub gtk_cancel_button		{ shift->{gtk_cancel_button}		}
sub fh				{ shift->{fh}				}
sub step			{ shift->{step}				}
sub output			{ shift->{output}			}
sub finished			{ shift->{finished}			}
sub is_active			{ shift->{is_active}			}
sub steps			{ shift->{steps}			}
sub max_value			{ shift->{max_value}			}
sub need_output			{ shift->{need_output}			}
sub open_next_step_callback	{ shift->{open_next_step_callback}	}
sub close_step_callback		{ shift->{close_step_callback}		}
sub finished_callback		{ shift->{finished_callback}		}
sub cancel_callback		{ shift->{cancel_callback}		}
sub get_progress_callback	{ shift->{get_progress_callback}	}

sub set_gtk_idle		{ shift->{gtk_idle}		= $_[1] }
sub set_gtk_cancel_button	{ shift->{gtk_cancel_button}	= $_[1] }
sub set_gtk_progress		{ shift->{gtk_progress}		= $_[1] }
sub set_output			{ shift->{output}		= $_[1] }
sub set_step			{ shift->{step}			= $_[1] }
sub set_fh			{ shift->{fh}			= $_[1] }
sub set_finished		{ shift->{finished}		= $_[1] }
sub set_is_active		{ shift->{is_active}		= $_[1] }
sub set_steps			{ shift->{steps}		= $_[1] }
sub set_max_value		{ shift->{max_value}		= $_[1] }
sub set_need_output		{ shift->{need_output}		= $_[1]	}
sub set_open_next_step_callback	{ shift->{open_next_step_callback}=$_[1]}
sub set_close_step_callback	{ shift->{close_step_callback}	= $_[1]	}
sub set_finished_callback	{ shift->{finished_callback}	= $_[1]	}
sub set_cancel_callback		{ shift->{cancel_callback}	= $_[1] }
sub set_get_progress_callback	{ shift->{get_progress_callback}= $_[1] }


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

	return $hbox;
}

sub open_steps_progress {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($steps, $label, $finished_callback, $cancel_callback) =
	@par{'steps','label','finished_callback','cancel_callback'};
	my  ($open_next_step_callback, $close_step_callback, $need_output) =
	@par{'open_next_step_callback','close_step_callback','need_output'};

	return if $self->is_active;
	$self->set_is_active(1);

	my $adj = Gtk::Adjustment->new ( 0, 1, $steps, 0, 0, 0); 
	my $progress = $self->gtk_progress;
	$progress->set_value(1);
	$progress->set_format_string ("$label %v/%u (%p%%)");
	$progress->set_show_text (1);
	$progress->set_adjustment($adj);

	my $idle = Gtk->idle_add ( sub { $self->steps_progress_next } );

	$self->set_steps($steps);
	$self->set_need_output($need_output);
	$self->set_finished_callback($finished_callback);
	$self->set_cancel_callback($cancel_callback);
	$self->set_open_next_step_callback($open_next_step_callback);
	$self->set_close_step_callback($close_step_callback);
	$self->set_step(0);

	$self->set_gtk_idle ( $idle );
	$self->set_fh ( undef );
	$self->set_output ( "" );

	if ( $cancel_callback ) {
		$self->gtk_cancel_button->show;
		$self->set_cancel_callback($cancel_callback);
	}

	1;
}

sub steps_progress_next {
	my $self = shift; $self->trace_in;
	
	if ( $self->finished ) {
		$self->execute_finished_callback;
		return 1;
	}

	my $fh       = $self->fh;
	my $progress = $self->gtk_progress;

	my $open_next_step_callback = $self->open_next_step_callback;
	my $close_step_callback     = $self->close_step_callback;
	my $finished_callback       = $self->finished_callback;

	if ( not $fh ) {
		# ok, start a new step
		my $step = $self->step;
		$self->set_step ($step);
		$fh = &$open_next_step_callback( step => $step );
		$self->set_output ("");

		if ( $fh == -1 ) {
			# abort operation
			$self->set_finished(1);

		} else {
			# ok, normal start operation
			$self->set_fh ($fh);
			$progress->set_value($step+1);
		}

	} else {
		# we are currently inside a started step
		my $buffer;
		my $rc = read ($fh, $buffer, 256);
		if ( not $rc ) {
			# ok step is finished
			my $step = $self->step;
			&$close_step_callback(
				step   => $step,
				fh     => $fh,
				output => $self->output
			);
			$self->set_fh (undef);
			++$step;

			if ( $step == $self->steps ) {
				# all steps are processed
				$self->set_finished(1);

			} else {
				# set next step
				$self->set_step ($step);
			}
		} else {
			# step is not finished yet
			if ( $self->need_output or
			     length($self->{output}) < 16384 ) {
				$self->{output} .= $buffer;
			}
		}
	}
	
	1;
}

sub open_continious_progress {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($max_value, $label, $fh, $need_output) =
	@par{'max_value','label','fh','need_output'};
	my  ($finished_callback, $get_progress_callback, $cancel_callback) =
	@par{'finished_callback','get_progress_callback','cancel_callback'};
	
	return if $self->is_active;
	$self->set_is_active(1);

	my $adj = Gtk::Adjustment->new ( 0, 1, $max_value, 0, 0, 0); 
	my $progress = $self->gtk_progress;
	$progress->set_value(1);
	$progress->set_format_string ("$label %p%%");
	$progress->set_show_text (1);
	$progress->set_adjustment($adj);

	my $idle = Gtk->idle_add ( sub { $self->continious_progress } );

	$self->set_max_value($max_value);
	$self->set_need_output($need_output);
	$self->set_finished_callback($finished_callback);
	$self->set_cancel_callback($cancel_callback);
	$self->set_get_progress_callback($get_progress_callback);

	$self->set_gtk_idle ( $idle );
	$self->set_fh ( $fh );
	$self->set_output ( "" );

	if ( $cancel_callback ) {
		$self->gtk_cancel_button->show;
		$self->set_cancel_callback($cancel_callback);
	}

	1;
}

sub continious_progress {
	my $self = shift; $self->trace_in;
	
	if ( $self->finished ) {
		$self->execute_finished_callback;
		return 1;
	}

	my $buffer;
	my $fh = $self->fh;
	my $rc = read ($fh, $buffer, 256);
	my $max_value = $self->max_value;

	if ( not $rc ) {
		# ok, we are finished
		$self->set_finished(1);
		$self->gtk_progress->set_value($max_value);

	} else {
		# we are still working
		if ( $self->need_output or length($self->{output}) < 16384 ) {
			$self->{output} .= $buffer;
		}
		my $get_progress_callback = $self->get_progress_callback;
		my ($value, $label) = &$get_progress_callback ( buffer => $buffer);
		while ( $value > $max_value ) {
			$value = $value - $max_value;
		}

		$self->gtk_progress->set_value($value) if $value;
		$self->gtk_progress->set_format_string($label) if $label;
	}
	
	1;
}

sub close_progress {
	my $self = shift; $self->trace_in;
	
	$self->gtk_progress->set_show_text(0);
	$self->gtk_progress->set_value(0);
	Gtk->idle_remove ( $self->gtk_idle );
	$self->set_finished(0);
	$self->set_gtk_idle(undef);
	$self->set_step (undef);
	$self->set_fh ( undef );
	$self->set_is_active(0);

	$self->gtk_cancel_button->hide;
	
	1;
}

sub cancel {
	my $self = shift;
	
	my $cancel_callback = $self->cancel_callback;
	&$cancel_callback();
	
	$self->close_progress;
	
	1;
}

sub execute_finished_callback {
	my $self = shift;
	
	my $finished_callback = $self->finished_callback;
	
	my $rc = eval {
		&$finished_callback( output => $self->output );
	};

	if ( not $rc or ref $rc or $@ ) {
		$self->close_progress;
	} elsif ( $rc ) {
		$self->set_finished(0);
	}

	if ( $@ )  {
		$self->long_message_window (
			message => $self->stripped_exception,
		);
	}

	&$rc() if ref $rc;

	1;
}

1;
