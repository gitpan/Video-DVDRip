# $Id: Text.pm,v 1.2 2003/02/05 22:17:07 joern Exp $

package Video::DVDRip::GUI::Setting::Text;

use strict;
use Carp;

use Video::DVDRip::GUI::Setting;
@Video::DVDRip::GUI::Setting::Text::ISA = qw(Video::DVDRip::GUI::Setting);

sub changed_signal_name	{ "changed" }

#===========================================================
#
# Additional new() parameters:
# ---------------------------
# maxlength			Entry maxlength
# presets			Preset values for combo box
# is_number			-> CheckedEntry
# is_min			-> CheckedEntry	
# is_max			-> CheckedEntry		
# may_empty			-> CheckedEntry	
# may_fractional		-> CheckedEntry	
# may_negative			-> CheckedEntry
# is_frame_or_timecode		-> CheckedEntry
# cond				-> CheckedEntry
#===========================================================

sub build {
	my $self = shift;
	my ($par) = @_;
	
	my $class = $par->{presets} ?
		"Video::DVDRip::CheckedCombo" :
		"Video::DVDRip::CheckedEntry";

	my @maxlength;
	@maxlength = ($par->{maxlength})
		if $class eq 'Video::DVDRip::CheckedEntry';

	my $entry = $class->new (
		@maxlength,
		is_number		=> $par->{is_number},
		is_min			=> $par->{is_min},			,
		is_max			=> $par->{is_max},
		may_empty		=> $par->{may_empty},
		may_fractional		=> $par->{may_fractional},
		may_negative		=> $par->{may_negative},
		is_frame_or_timecode	=> $par->{is_frame_or_timecode},
		cond			=> $par->{cond},
	);
	
	$par->{usize} ||= 40;
	
	if ( $class eq 'Video::DVDRip::CheckedEntry' ) {
		$entry->set_usize($par->{usize},undef);
		$self->set_parent_widget ( $entry );
		$self->set_widget ( $entry );
	} else {
		$entry->entry->set_usize($par->{usize},undef);
		$entry->set_popdown_strings( @{$par->{presets}} );
		$self->set_parent_widget ( $entry );
		$self->set_widget ( $entry->entry );
	}

	$entry->show;

	1;
}

sub get_value {
	my $self = shift;
	
	return $self->widget->get_text;
}

sub set_value {
	my $self = shift;

	$self->widget->set_text($_[0]);

	1;
}

