# $Id: Config.pm,v 1.22 2005/04/23 14:32:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Config;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Window;

use strict;
use Carp;

sub single_instance_window { 1 }

sub page2params			{ shift->{page2params}			}
sub set_page2params		{ shift->{page2params}		= $_[1]	}

sub gtk_notebook		{ shift->{gtk_notebook}			}
sub set_gtk_notebook		{ shift->{gtk_notebook}		= $_[1]	}

sub gtk_result_text		{ shift->{gtk_result_text}		}
sub set_gtk_result_text		{ shift->{gtk_result_text}	= $_[1]	}

# GUI Stuff ----------------------------------------------------------

sub build {
	my $self = shift; $self->trace_in;

	my %page2params;

	my $win = Gtk::Window->new ( -toplevel );
	$win->set_title($self->config('program_name')." ".__"Preferences");
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

	my $frame = Gtk::Frame->new (__"Global Preferences");
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

	my $notebook = Gtk::Notebook->new;
	$notebook->set_tab_pos ('top');
	$notebook->set_homogeneous_tabs(0);
	$notebook->show;

	$frame_vbox->pack_start ($notebook, 0, 1, 0);

	$self->set_gtk_notebook($notebook);

	my $config_object = $self->config_object;

	my ($label, $order);
	my $page_no = 0;
	for (my $i=0; $i < @{$config_object->order}; ) {
		$label = $config_object->order->[$i];
		$order = $config_object->order->[$i+1];
		$i += 2;

		my @fields;
		foreach my $field ( @{$order} ) {
			push @{$page2params{$page_no}}, $field;
			my %field = %{$config_object->config->{$field}};
			$field{name} = $field;
			my $onload = $field{onload};
			if ( $field{type} eq 'switch' ) {
				$field{onchange} = sub {
					$config_object->set_value ($field, $_[0]);
					&$onload() if $onload;
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
					&$onload($value) if $onload;
				};
			}
			push @fields, \%field;
		}
	
		my $table = $self->create_dialog ( @fields );
		my $table_vbox = Gtk::VBox->new;
		$table_vbox->set_border_width(10);
		$table_vbox->show;
		$table_vbox->pack_start($table, 0, 1, 0);
		$notebook->append_page ($table_vbox, Gtk::Label->new(" $label "));
		
		++$page_no;
	}

	# Check & Ok button
	my $align = Gtk::Alignment->new ( 1, 0, 0, 1);
	$align->show;
	$hbox = Gtk::HBox->new;
	$hbox->show;
	$align->add ($hbox);
	$frame_vbox->pack_start ($align, 0, 1, 0);

	my $button = Gtk::Button->new_with_label (__"Check all settings");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->check_params ( all_pages => 1 ) } );
	$hbox->pack_start ($button, 0, 1, 0);

	# Check current settings button

	$button = Gtk::Button->new_with_label (__"Check settings on this page");
	$button->show;
	$button->signal_connect ( "clicked", sub { $self->check_params } );
	$hbox->pack_start ($button, 0, 1, 0);

	# Ok Button

	$button = Gtk::Button->new_with_label ("          Ok          ");
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

	# Check output
	my $text_frame = Gtk::Frame->new (__"Check results");
	$text_frame->show;
	$frame_vbox->pack_start ($text_frame, 0, 1, 0);

	my $text_vbox = Gtk::VBox->new;
	$text_vbox->set_border_width(10);
	$text_vbox->show;
	$text_frame->add($text_vbox);

	my $text_table = new Gtk::Table( 2, 2, 0 );
	$text_table->set_row_spacing( 0, 2 );
	$text_table->set_col_spacing( 0, 2 );
	$text_table->show();
	$text_vbox->pack_start ($text_table, 0, 1, 0);	

	my $text = new Gtk::Text( undef, undef );
	$text->show;
	$text->set_usize (undef, 120);
	$text->set_editable( 0 );
	$text->set_word_wrap ( 1 );
	$text_table->attach( $text, 0, 1, 0, 1,
        	       [ 'expand', 'shrink', 'fill' ],
        	       [ 'expand', 'shrink', 'fill' ],
        	       0, 0 );

	$self->set_gtk_result_text ($text);

	my $vscrollbar = new Gtk::VScrollbar( $text->vadj );
	$text_table->attach( $vscrollbar, 1, 2, 0, 1, 'fill',
        	       [ 'expand', 'shrink', 'fill' ], 0, 0 );
	$vscrollbar->show();

	# store component
	$self->set_comp ( config => $self );
	$self->set_widget($win);
	$self->set_gtk_window_widget($win);

	$self->set_page2params ( \%page2params );

	$notebook->signal_connect ("switch-page", sub {
		$self->check_params ( page => $_[2] );
	});

	$self->check_params;

	$win->show;

	return 1;
}

sub check_params {
	my $self = shift;
	my %par = @_;
	my ($page, $all_pages) = @par{'page','all_pages'};

	my @pages;
	if ( not $all_pages ) {
		$page = $self->gtk_notebook->get_current_page
			if not defined $page;
		push @pages, $page;
	} else {
		@pages = sort { $a <=> $b } keys %{$self->page2params};
	}

	my $text          = $self->gtk_result_text;
	my $config_object = $self->config_object;
	
	$text->freeze;
	$text->set_point( 0 );
	$text->forward_delete( $text->get_length );

	my $red;
	$red->{red}   = 0xFFFF;
	$red->{green} = 0;
	$red->{blue}  = 0;

	my $green;
	$green->{red}   = 0;
	$green->{green} = 80*256;
	$green->{blue}  = 30*256;

	my ($options, $method);
	foreach $page ( @pages ) {
		$options = $self->page2params->{$page};
		foreach my $option ( @{$options} ) {
			$text->insert (
				undef, undef, undef,
				$config_object->config->{$option}->{label}.": "
			);
			my $result;
			$method = "test_$option";
			if ( $config_object->can ($method) ) {
				$result = $config_object->$method($option);
			} else {
				$result = __"not tested : Ok";
			}
			$text->insert ( undef, ($result =~ /NOT/ ? $red : $green), undef, $result."\n" );
		}
		$text->insert ( undef, undef, undef, "\n" );
	}
	
	$text->thaw;

	1;
}

1;
