package Video::DVDRip::CheckedEntry;

# use strict;

use base Gtk::Entry;

sub is_number			{ shift->{is_number}			}
sub is_min			{ shift->{is_min}			}
sub is_max			{ shift->{is_max}			}
sub is_frame_or_timecode	{ shift->{is_frame_or_timecode}		}
sub may_empty			{ shift->{may_empty}			}
sub may_fractional		{ shift->{may_fractional}		}
sub may_negative		{ shift->{may_negative}			}
sub cond			{ shift->{cond}				}

sub set_is_number		{ shift->{is_number}		= $_[1]	}
sub set_is_min			{ shift->{is_min}		= $_[1]	}
sub set_is_max			{ shift->{is_max}		= $_[1]	}
sub set_may_empty		{ shift->{may_empty}		= $_[1]	}
sub set_may_fractional		{ shift->{may_fractional}	= $_[1]	}
sub set_may_negative		{ shift->{may_negative}		= $_[1]	}
sub set_is_frame_or_timecode	{ shift->{is_frame_or_timecode}	= $_[1]	}
sub set_cond			{ shift->{cond}			= $_[1]	}

sub old_val			{ shift->{old_val}			}
sub set_old_val			{ shift->{old_val}		= $_[1]	}

sub new {
	my $class = shift;
	my ($max_length, %par) = @_;
	my  ($is_number, $is_min, $is_max, $may_empty, $may_fractional) =
	@par{'is_number','is_min','is_max','may_empty','may_fractional'};
	my  ($may_negative, $is_frame_or_timecode, $cond) =
	@par{'may_negative','is_frame_or_timecode','cond'};

	my $self = bless $class->SUPER::new ($max_length), $class;

	$self->set_is_number ($is_number);
	$self->set_may_empty ($may_empty);
	$self->set_may_fractional ($may_fractional);
	$self->set_is_min ($is_min);
	$self->set_is_max ($is_max);
	$self->set_may_negative ($may_negative);
	$self->set_is_frame_or_timecode ($is_frame_or_timecode);
	$self->set_cond($cond);

	$self->connect_check_signals;

	return $self;
}

sub connect_check_signals {
	my $self = shift;

	$self->signal_connect ("focus-in-event", sub {
		$self->set_old_val ( $self->get_text );
		1;
	});

	$self->signal_connect ("focus-out-event", sub {
		$self->check_value;
		1;
	});

	1;
}

sub check_value {
	my $self = shift;

	my $val = $self->get_text;

	my $restore;
	my $cond = $self->cond;
	if ( $cond ) {
		$restore = ! &$cond($val);
	}

	if ( not $self->may_empty and $val eq '' ) {
		$restore = 1;
	}

	if ( not $restore and $self->is_number and $val ne '' ) {
		if ( $self->may_fractional ) {
			$restore = 1 if $val !~ /^-?\d+(\.\d+)?$/;
		} else {
			$restore = 1 if $val !~ /^-?\d+$/;
		}
		$restore = 1 if defined $self->is_min and $val < $self->is_min;
		$restore = 1 if defined $self->is_max and $val > $self->is_max;
		$restore = 1 if not $self->may_negative and $val < 0;
	}

	if ( not $restore and $self->is_frame_or_timecode ) {
		$restore = 1 if $val !~ /^(\d+|\d\d:\d\d:\d\d)$/;
	}

	if ( $restore ) {
		Video::DVDRip::GUI::Base->message_window (
			message =>
				"'$val' is an illegal value here.\n".
				"Old value '".$self->old_val."' was restored."
		);
		$val = $self->old_val;
		$val || 0 if not $self->may_empty;
		$self->set_text ($val);
		
	}
	
	1;
}

package Video::DVDRip::CheckedCombo;

use base Gtk::Combo;

sub new {
	my $class = shift;
	my %par = @_;
	my  ($is_number, $is_min, $is_max, $may_empty, $may_fractional) =
	@par{'is_number','is_min','is_max','may_empty','may_fractional'};
	my  ($may_negative) =
	@par{'may_negative'};

	my $self = $class->SUPER::new;

	my $entry = $self->entry;
	bless $entry, "Video::DVDRip::CheckedEntry";

	$entry->set_is_number ($is_number);
	$entry->set_is_min ($is_min);
	$entry->set_is_max ($is_max);
	$entry->set_may_empty ($may_empty);
	$entry->set_may_fractional ($may_fractional);
	$entry->set_may_negative ($may_negative);

	$entry->connect_check_signals;

	return $self;
}


1;
