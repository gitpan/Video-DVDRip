# $Id: Checkbox.pm,v 1.1 2003/01/27 14:16:58 joern Exp $

package Video::DVDRip::GUI::Setting::Checkbox;

use strict;
use Carp;

use Video::DVDRip::GUI::Setting;
@Video::DVDRip::GUI::Setting::Checkbox::ISA = qw(Video::DVDRip::GUI::Setting);

sub changed_signal_name	{ "clicked" }

sub build {
	my $self = shift;

	my $checkbox = Gtk::CheckButton->new;
	$checkbox->show;
	
	$self->set_parent_widget ( $checkbox );
	$self->set_widget ( $checkbox );

	1;
}

sub get_value {
	my $self = shift;
	
	return $self->widget->get_active ? 1 : 0;
}

sub set_value {
	my $self = shift;

	$self->widget->set_active($_[0]);

	1;
}

