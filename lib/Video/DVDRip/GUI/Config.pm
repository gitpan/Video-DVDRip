# $Id: Config.pm,v 1.15 2002/03/02 16:21:08 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Config;

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

sub single_instance_window { 1 }

# GUI Stuff ----------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name'). " Preferences");
	$win->signal_connect("destroy" => sub {
		$self->set_comp (config => undef);
	});
	$win->border_width(0);
	$win->set_uposition (10,10);
	$win->realize;

	# Build dialog
	my $vbox = Gtk::VBox->new;
	$vbox->show;
	$vbox->set_border_width(10);
	$win->add($vbox);

	my $frame = Gtk::Frame->new ("Global Preferences");
	$frame->show;
	$vbox->pack_start($frame, 0, 1, 0);

	my $hbox = Gtk::HBox->new;
	$hbox->show,
	$hbox->set_border_width(10);
	$frame->add($hbox);

	my $frame_vbox = Gtk::VBox->new;
	$frame_vbox->show;
	$frame_vbox->set_border_width(5);
	$hbox->pack_start($frame_vbox, 0, 1, 0);

	my @fields;
	my $config_object = $self->config_object;
	foreach my $field ( @{$config_object->order} ) {
		my %field = %{$config_object->config->{$field}};
		if ( $field{type} eq 'switch' ) {
			$field{onchange} = sub {
				$config_object->set_value ($field, $_[0]);
			};
		} else {
			$field{onchange} = sub {
				my $value = $_[0]->get_text;
				if ( $field{type} eq 'file' or $field{type} eq 'dir' ) {
					if ( $value !~ m!^/! ) {
						$value = "/$value";
						$_[0]->set_text($value);
					}
				}
				$config_object->set_value (
					$field, $value
				);
			};
		}
		push @fields, \%field;
	}
	
	my $table = $self->create_dialog ( @fields );
	$frame_vbox->pack_start($table, 0, 1, 0);

	# ok button
	my $align = Gtk::Alignment->new ( 1, 0, 0, 1);
	$align->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$align->add ($hbox);
	my $button = Gtk::Button->new_with_label ("     Ok     ");
	$button->show;
	$button->signal_connect ( "clicked", sub {
		$config_object->save;
		$win->destroy;
		my $project = eval { $self->comp('project') };
		return if not $project;
		$project->project->set_dvd_device (
			$config_object->get_value('dvd_device')
		);
	} );
	$hbox->pack_start ($button, 0, 1, 0);
	$frame_vbox->pack_start ($align, 0, 1, 0);

	# store component
	$self->set_comp ( config => $self );
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);

	$win->show;

	return 1;
}

1;
