# $Id: Progress.pm,v 1.15 2002/01/30 22:46:33 joern Exp $

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

sub gtk_input			{ shift->{gtk_input}			}
sub gtk_progress		{ shift->{gtk_progress}			}
sub gtk_cancel_button		{ shift->{gtk_cancel_button}		}

sub set_gtk_input		{ shift->{gtk_input}		= $_[1] }
sub set_gtk_cancel_button	{ shift->{gtk_cancel_button}	= $_[1] }
sub set_gtk_progress		{ shift->{gtk_progress}		= $_[1] }

sub fh				{ shift->{fh}				}
sub label			{ shift->{label}			}
sub output			{ shift->{output}			}
sub state			{ shift->{state}			}
sub max_value			{ shift->{max_value}			}
sub last_value			{ shift->{last_value}			}
sub need_output			{ shift->{need_output}			}
sub start_time			{ shift->{start_time}			}
sub log_time			{ shift->{log_time}			}
sub log_percent			{ shift->{log_percent}			}
sub show_percent		{ shift->{show_percent}			}
sub show_fps			{ shift->{show_fps}			}
sub show_eta			{ shift->{show_eta}			}

sub set_fh			{ shift->{fh}			= $_[1] }
sub set_label			{ shift->{label}		= $_[1] }
sub set_output 			{ shift->{output}		= $_[1]	}
sub set_max_value		{ shift->{max_value}		= $_[1] }
sub set_last_value		{ shift->{last_value}		= $_[1] }
sub set_need_output		{ shift->{need_output}		= $_[1]	}
sub set_start_time		{ shift->{start_time}		= $_[1]	}
sub set_log_time		{ shift->{log_time}		= $_[1]	}
sub set_log_percent		{ shift->{log_percent}		= $_[1]	}
sub set_show_percent		{ shift->{show_percent}		= $_[1] }
sub set_show_fps		{ shift->{show_fps}		= $_[1] }
sub set_show_eta		{ shift->{show_eta}		= $_[1] }

sub open_callback		{ shift->{open_callback}		}
sub progress_callback		{ shift->{progress_callback}		}
sub cancel_callback		{ shift->{cancel_callback}		}
sub close_callback		{ shift->{close_callback}		}

sub set_open_callback		{ shift->{open_callback}	= $_[1]	}
sub set_progress_callback	{ shift->{progress_callback}	= $_[1]	}
sub set_cancel_callback		{ shift->{cancel_callback}	= $_[1]	}
sub set_close_callback		{ shift->{close_callback}	= $_[1]	}

my %KNOWN_STATES = (
	idle      => { ''      => 1, running => 1, cancelled => 1 },
	opened    => { idle    => 1 },
	running   => { opened  => 1, running => 1 },
	cancelled => { running => 1 },
);

sub set_state {
	my $self = shift;
	my ($state) = @_;
	
	croak "Unknown progress state '$state'"
		if not defined $KNOWN_STATES{$state};

	my $old_state = $self->state;
	
	croak "Illegal progress state change from '$old_state' to '$state'"
		if not defined $KNOWN_STATES{$state}->{$old_state};

	return $self->{state} = $state;
}

sub is_active {
	my $self = shift;
	return $self->state ne 'idle';
}

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

	$self->set_state ('idle');

	return $hbox;
}

sub open {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($max_value, $label, $need_output, $open_callback) =
	@par{'max_value','label','need_output','open_callback'};
	my  ($progress_callback, $cancel_callback, $close_callback) =
	@par{'progress_callback','cancel_callback','close_callback'};
	my  ($show_fps, $show_eta, $show_percent) =
	@par{'show_fps','show_eta','show_percent'};

	$self->set_state ( 'opened' );
	
	my $adj = Gtk::Adjustment->new ( 0, 0, $max_value, 0, 0, 0); 
	my $progress = $self->gtk_progress;
	$progress->set_adjustment($adj);
	$progress->set_format_string ($label);
	$progress->set_show_text (1);
	$progress->set_value(1);

	$self->set_label($label);
	$self->set_max_value($max_value);
	$self->set_last_value(0);
	$self->set_need_output($need_output);
	$self->set_log_percent(10);
	$self->set_show_fps($show_fps);
	$self->set_show_eta($show_eta);
	$self->set_show_percent($show_percent);
	
	$self->set_open_callback     ( $open_callback );
	$self->set_progress_callback ( $progress_callback );
	$self->set_cancel_callback   ( $cancel_callback );
	$self->set_close_callback    ( $close_callback );

	$self->gtk_cancel_button->show if $cancel_callback;
	$self->gtk_cancel_button->hide if not $cancel_callback;

	$self->set_start_time (time);
	$self->set_log_time ( 60 );

	$self->log ("Starting task '".$self->label."'...");
	
	$self->init_pipe ( fh => &$open_callback ( progress => $self ) );

	1;
}

sub init_pipe {
	my $self = shift;
	my %par = @_;
	my ($fh) = @par{'fh'};

	$self->set_fh ( $fh );
	$self->set_output ( "" );
	
	$self->set_state ('running');

	Gtk::Gdk->input_remove ( $self->gtk_input ) if defined $self->gtk_input;
	$self->set_gtk_input ( Gtk::Gdk->input_add ( $fh->fileno, 'read', sub { $self->progress } ) );

	1;
}

sub progress {
	my $self = shift; $self->trace_in;
	
	my $fh = $self->fh;

	# read all date from the pipe
	my ($tmp, $buffer);
	while ( $fh->read ($tmp, 8192) ) {
		$buffer .= $tmp;
	}

	# store output
	if ( $self->need_output or length($self->{output}) < 16384 ) {
		$self->{output} .= $buffer;
	}

	# are we finished?
	if ( $! != EAGAIN ) {
		my $close_callback = $self->close_callback;
		my $rc = &$close_callback (
			progress => $self,
			output   => $self->{output}.$buffer
		);

		if ( $rc eq 'finished' ) {
			$self->close;
		} elsif ( ref $rc eq 'CODE' ) {
			$self->close;
			&$rc();
		} elsif ( $rc eq 'continue' ) {
			$self->log ("Continue this task with '".$self->label."'");
		} else {
			croak "Illegal close_callback return value '$rc'";
		}
		return 1;
	}

	my $progress_callback = $self->progress_callback;
	my $value = &$progress_callback (
		progress => $self,
		buffer   => $buffer
	);

	if ( $value < $self->last_value ) {
		$value = $self->last_value;
	} else {
		$self->set_last_value($value);
	}

	my $max_value = $self->max_value;
	while ( $value > $max_value ) {
		$value = $value - $max_value;
	}

	if ( $value > 0 ) {
		my ($eta, $elapsed, $fps, $percent_fmt);

		my $percent = 100*$value/$max_value;
		my $time = time - $self->start_time;

		if ( $self->show_percent ) {
			$percent_fmt = sprintf (", %3.2f%%%%", $percent);
		}

		if ( $time and $self->show_eta ) {
			$eta = ", ETA: ".$self->format_time (
				time => int($time * $max_value / $value) - $time
			);
		}

		if ( $time > 5 and $self->show_fps ) {
			$fps = sprintf(", %2.1f fps", $value/$time);
		}

		$elapsed = ", Elapsed: ".$self->format_time ( time => $time );

		$self->gtk_progress->set_format_string (
			$self->label."$percent_fmt$fps$elapsed$eta"
		);

		$self->gtk_progress->set_value($value) if $value > 0;
		
		if ( not $self->show_percent ) {
			if ( $time >= $self->log_time ) {
				$self->log (
					"Still working on '".
					$self->label."'..."
				);
				$self->set_log_time ( $time + 60 );
			}
		
		} elsif ( $percent > $self->log_percent ) {
			$percent = int($percent/10)*10;
			$self->set_log_percent($percent+10);
			$self->log ("Processed $percent\%...");
		}
	}

	1;
}

sub close {
	my $self = shift; $self->trace_in;
	
	$self->gtk_progress->set_show_text(0);
	$self->gtk_progress->set_value(0);

	Gtk::Gdk->input_remove ( $self->gtk_input );

	$self->set_gtk_input(undef);
	$self->set_fh ( undef );

	$self->gtk_cancel_button->hide;
	
	$self->set_state ('idle');

	$self->log ("Task '".$self->label."' finished.");

	1;
}

sub cancel {
	my $self = shift;
	
	$self->set_state ('cancelled');
	
	my $cancel_callback = $self->cancel_callback;
	&$cancel_callback( progress => $self );
	
	$self->log ("User cancelled task '".$self->label."'.");

	$self->close;

	1;
}

1;

__END__

Progress Phasen:
----------------

1. Initialisierung
   - Progress Bar anzeigen
   - callback aufrufen
     - Pipe öffnen
   - Max Value setzen
   - idle callback setzen

2. Progress Bar updaten
   - callback aufrufen
     - progress value zurückgeben
   - Bar ausgeben
   - ETA berechnen und ausgeben
   - Ausgabe ins Logfile

3. Cancel
   - callback aufrufen
   - Progress Bar beenden

4. Progress Bar beenden
   - callback aufrufen
     - je nach Rückgabewert Progress Bar nicht beenden,
       => Wiederbenutzung / Steps Progress
   - Progress Bar unsichtbar machen
   - idle callback löschen

