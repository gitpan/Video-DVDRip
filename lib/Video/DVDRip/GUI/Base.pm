# $Id: Base.pm,v 1.16 2002/06/29 20:39:54 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Base;

use base Video::DVDRip::Base;

use strict;
use Carp;
use Data::Dumper;
use Cwd;

my %COMPONENTS;

sub comp {
	my $self = shift;
	my ($name) = @_;
	confess "unknown component '$name'"
		if not defined $COMPONENTS{$name};
	return $COMPONENTS{$name};
}

sub set_comp {
	my $self = shift;
	my ($name, $object) = @_;
	return $COMPONENTS{$name} = $object;
}

sub show_file_dialog {
	my $self = shift;
	my %par = @_;
	my  ($dir, $filename, $cb, $title, $confirm) =
	@par{'dir','filename','cb','title','confirm'};
	
	my $cwd = cwd;
	chdir ( $dir );
	
	# Create a new file selection widget
	my $dialog = new Gtk::FileSelection( $title );

	# Connect the ok_button to file_ok_sel function
	$dialog->ok_button->signal_connect(
		"clicked",
		sub { $self->cb_commit_file_dialog (@_, $confirm) },
		$cb, $dialog
	);

	# Connect the cancel_button to destroy the widget
	$dialog->cancel_button->signal_connect(
		"clicked", sub { $dialog->destroy }
	);

	$dialog->set_filename( $filename );
	$dialog->set_position ( "mouse" );
	$dialog->show();
	
	chdir ($cwd);

	1;
}

sub cb_commit_file_dialog {
	my $self = shift;
	my ($button, $cb, $dialog, $confirm) = @_;
	
	my $filename = $dialog->get_filename();
	
	if ( -f $filename and $confirm ) {
		$self->confirm_window (
			message => "Overwrite existing file '$filename'?",
			yes_callback => sub { &$cb($filename); $dialog->destroy },
			position => 'mouse'
		);
	} else {
		&$cb($filename);
		$dialog->destroy;
	}

	1;
}

sub confirm_window {
	my $self = shift;
	my %par = @_;
	my  ($message, $yes_callback, $no_callback, $position, $yes_label, $no_label) =
	@par{'message','yes_callback','no_callback','position','yes_label','no_label'};
	
	$yes_label ||= "Ok";
	$position ||= "center";

	my $confirm = Gtk::Dialog->new;
	my $label = Gtk::Label->new ($message);
	$confirm->vbox->pack_start ($label, 1, 1, 0);
	$confirm->border_width(10);
	$confirm->set_title ("Confirmation");
	$label->show;

	my $cancel = Gtk::Button->new ("Cancel");
	$confirm->action_area->pack_start ( $cancel, 1, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $confirm->destroy } );
	$cancel->show;

	if ( $no_label ) {
		my $no = Gtk::Button->new ($no_label);
		$confirm->action_area->pack_start ( $no, 1, 1, 0 );
		$no->signal_connect( "clicked", sub { $confirm->destroy; &$no_callback } );
		$no->show;
	}

	my $ok = Gtk::Button->new ($yes_label);
	$confirm->action_area->pack_start ( $ok, 1, 1, 0 );
	$ok->can_default(1);
	$ok->grab_default;
	$ok->signal_connect( "clicked", sub { $confirm->destroy; &$yes_callback } );
	$ok->show;

	$confirm->set_position ($position);
	$confirm->set_modal (1);
	$confirm->show;

	1;
}

sub message_window {
	my $self = shift;
	my %par = @_;
	my ($message) = @par{'message'};
	
	my $dialog = Gtk::Dialog->new;

	my $label = Gtk::Label->new ("\n".$message."\n");
	$dialog->vbox->pack_start ($label, 1, 1, 0);
	$dialog->border_width(10);
	$dialog->set_title ("Video::DVDRip Message");
	$dialog->set_default_size (250, 150);
	$label->show;

	my $ok = Gtk::Button->new ("Ok");
	$dialog->action_area->pack_start ( $ok, 1, 1, 0 );
	$ok->signal_connect( "clicked", sub { $dialog->destroy } );
	$ok->show;

	$dialog->set_position ("center");
	$dialog->show;

	1;	
	
}

sub gdk_color {
	my $self = shift;
	my ($html_color) = @_;
	
	$html_color =~ s/^#//;
	
	my ($r, $g, $b) = ( $html_color =~ /(..)(..)(..)/ );

	my $cmap = Gtk::Gdk::Colormap->get_system();
	my $color = {
		red   => hex($r) * 256,
		green => hex($g) * 256,
		blue  => hex($b) * 256,
	};
	
	if ( not $cmap->color_alloc ($color) ) {
		warn ("Couldn't allocate color $html_color");
	}
	
	return $color;
}

sub create_text_entry {
	my $self = shift;
	my %par = @_;
	my ($label, $value) = @par{'label','value'};
	
	my ($hbox, $e, $l);
	
	$l = Gtk::Label->new ($label);
	$l->show;
	$e = Gtk::Entry->new;
	$e->set_text($value);
	$e->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$hbox->pack_start ($l, 0, 1, 0);
	$hbox->pack_start ($e, 0, 1, 0);
	
	return $hbox;
}

sub create_dialog {
	my $self = shift;
	my @fields = @_;

	my $table = Gtk::Table->new ( scalar(@fields), 2, 0 );
	$table->show;

	my ($i, @widgets);
	foreach my $field ( @fields ) {
		my $label = Gtk::Label->new ($field->{label});
		$label->show;
		my $hbox = Gtk::HBox->new;
		$hbox->show;
		$hbox->pack_start($label, 0, 1, 0);
		$table->attach_defaults ($hbox, 0, 1, $i, $i+1);
		
		if ( $field->{readonly} and $field->{type} eq 'switch' ) {
			$label = Gtk::Label->new ( $field->{value} ? 'Yes' : 'No' );
			$label->show;
			$table->attach_defaults ($label, 1, 2, $i, $i+1);

		} elsif ( $field->{readonly} ) {
			$label = Gtk::Label->new ( $field->{value} );
			$label->show;
			$table->attach_defaults ($label, 1, 2, $i, $i+1);
		
		} elsif ( $field->{type} eq 'switch' ) {
			$hbox = Gtk::HBox->new;
			$hbox->show;
			my $radio_yes = Gtk::RadioButton->new ("Yes");
			$radio_yes->show;
			$hbox->pack_start($radio_yes, 0, 1, 0);
			my $radio_no = Gtk::RadioButton->new ("No", $radio_yes);
			$radio_no->show;
			$hbox->pack_start($radio_no, 0, 1, 0);

			$table->attach_defaults ($hbox, 1, 2, $i, $i+1);

			if ( $field->{onchange} ) {
				my $cb = $field->{onchange};
				$radio_yes->signal_connect (
					"clicked", sub { &$cb(1) }
				);
				$radio_no->signal_connect (
					"clicked", sub { &$cb(0) }
				);
			}
			
			if ( $field->{value} ) {
				$radio_yes->set_active(1);
			} else {
				$radio_no->set_active(1);
			}
			
		} elsif ( $field->{type} eq 'string' and $field->{presets} ) {
			my $entry = Gtk::Combo->new;
			$entry->show;
			$entry->set_popdown_strings (@{$field->{presets}});
			$entry->set_usize(($field->{width}||300),undef);
			$entry->entry->set_text ($field->{value});
			if ( $field->{onchange} ) {
				$entry->entry->signal_connect (
					"changed", $field->{onchange},
				);
			}
			push @widgets, $entry;
			$table->attach_defaults ($entry, 1, 2, $i, $i+1);

		} else {
			my $entry;
			$entry = Gtk::Entry->new;
			$entry->set_visibility (0) if $field->{type} eq 'password'; 
			$entry->set_text ($field->{value});
			$entry->set_usize(($field->{width}||300),undef);
			$entry->show;
			if ( $field->{onchange} ) {
				$entry->signal_connect (
					"changed", $field->{onchange}
				);
			}
			push @widgets, $entry;
			$table->attach_defaults ($entry, 1, 2, $i, $i+1);
		}
		++$i;
	}

	$table->set_row_spacings ( 10 );
	$table->set_col_spacings ( 10 );

	return $table if not wantarray;
	return ($table, \@widgets);
}

sub long_message_window {
	my $self = shift;
	my %par = @_;
	my ($message) = @par{'message'};

	my $win = Gtk::Window->new;
	$win->set_title ("Video::DVDRip Message");
	$win->set_default_size (620, 400);
	$win->set_position ("center");

	my $vbox = Gtk::VBox->new;
	$vbox->show;
	$vbox->set_border_width(10);
	$win->add($vbox);

	my $text_table = new Gtk::Table( 2, 2, 0 );
	$text_table->show();
	$text_table->set_row_spacing( 0, 2 );
	$text_table->set_col_spacing( 0, 2 );
	$vbox->pack_start($text_table, 1, 1, 0);

	my $text = new Gtk::Text( undef, undef );
	$text->show;
	$text->set_usize (undef, 100);
	$text->set_editable( 0 );
	$text->set_word_wrap ( 0 );
	$text->insert (undef, undef, undef, $message);
	$text_table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );

	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$vscrollbar->show();
	$text_table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );

	my $ok = Gtk::Button->new (" Ok ");
	$ok->show;
	$ok->signal_connect( "clicked", sub { $win->destroy } );

	$vbox->pack_start ( $ok, 0, 1, 0 );

	$win->show;

	return $text;
}

1;
