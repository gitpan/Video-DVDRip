# $Id: ImageClip.pm,v 1.11 2002/10/15 21:08:33 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::ImageClip;

use Gtk::Gdk::Pixbuf;

use strict;
use Carp;

use File::Basename;
use File::Copy;
use Data::Dumper;

sub widget			{ shift->{widget}			}
sub drawing_area		{ shift->{drawing_area}			}
sub knobs			{ shift->{knobs}			}
sub thumbnail			{ shift->{thumbnail}			}

sub gdk_pixbuf			{ shift->{gdk_pixbuf}			}
sub width			{ shift->{width}			}
sub height			{ shift->{height}			}
sub knob_size			{ shift->{knob_size}			}
sub clip_top			{ shift->{clip_top}			}
sub clip_bottom			{ shift->{clip_bottom}			}
sub clip_left			{ shift->{clip_left}			}
sub clip_right			{ shift->{clip_right}			}
sub dragged_knob		{ shift->{dragged_knob}			}
sub grid			{ shift->{grid}				}
sub changed_callback		{ shift->{changed_callback}		}
sub no_clip			{ shift->{no_clip}			}
sub image_width			{ shift->{image_width}			}
sub image_height		{ shift->{image_height}			}

sub set_gdk_pixbuf		{ shift->{gdk_pixbuf}		= $_[1] }
sub set_width			{ shift->{width}		= $_[1]	}
sub set_height			{ shift->{height}		= $_[1]	}
sub set_knob_size		{ shift->{knob_size}		= $_[1] }
sub set_clip_top		{ shift->{clip_top}		= $_[1] }
sub set_clip_bottom		{ shift->{clip_bottom}		= $_[1] }
sub set_clip_left		{ shift->{clip_left}		= $_[1] }
sub set_clip_right		{ shift->{clip_right}		= $_[1] }
sub set_dragged_knob		{ shift->{dragged_knob}		= $_[1] }
sub set_grid			{ shift->{grid}			= $_[1] }
sub set_changed_callback	{ shift->{changed_callback}	= $_[1] }
sub set_no_clip			{ shift->{no_clip}		= $_[1] }
sub set_image_width		{ shift->{image_width}		= $_[1] }
sub set_image_height		{ shift->{image_height}		= $_[1] }

sub new {
	my $type = shift;
	my %par = @_;
	my  ($gtk_window, $filename, $width, $height, $thumbnail) =
	@par{'gtk_window','filename','width','height','thumbnail'};
	my  ($changed_callback, $no_clip, $show_tooltips) =
	@par{'changed_callback','no_clip','show_tooltips'};

	my $drawing_area = Gtk::DrawingArea->new;
	my $event_box = Gtk::EventBox->new;

	my $self = bless {
		drawing_area     => $drawing_area,
		event_box        => $event_box,
		widget           => $event_box,
		gdk_pixbuf       => undef,
		width            => $width,
		height           => $height,
		thumbnail        => $thumbnail,
		no_clip		 => $no_clip,
		changed_callback => $changed_callback,
		clip_top         => 16,
		clip_bottom      => 16,
		clip_left        => 16,
		clip_right       => 16,
		knob_size        => 11,
		knobs            => {},
		grid             => 2,
	}, $type;

	if ( $filename ) {
		$self->load_image ( filename => $filename);
		$width  ||= $self->gdk_pixbuf->get_width;
		$height ||= $self->gdk_pixbuf->get_height;
	}

	$drawing_area->size ($width, $height);
	$drawing_area->show;
	$drawing_area->signal_connect ('configure_event', sub { $self->draw });
	$drawing_area->signal_connect ('expose_event', sub { $self->draw });
	
	$event_box->show;
	$event_box->add ($drawing_area);
	
	if ( $show_tooltips ) {
		my $tooltip = Gtk::Tooltips->new;
		$tooltip->set_tip ($event_box, "Click on the image to open a window", "test");
		$tooltip->enable;
		$tooltip->set_delay(0);
	}

	if ( not $thumbnail ) {
		$event_box->set_events( 'button_press_mask' );
		$event_box->signal_connect (
			'button_press_event', sub { $self->button_press(@_) }
		);
		$event_box->signal_connect (
			'button_release_event', sub { $self->button_release(@_) }
		);
		$event_box->signal_connect (
			'motion_notify_event', sub { $self->motion_notify(@_) }
		);

		$self->calculate_knobs;
	}

	return $self;
}

sub load_image {
	my $self = shift;
	my %par = @_;
	my ($filename) = @par{'filename'};

	my $gdk_pixbuf = Gtk::Gdk::Pixbuf->new_from_file($filename);

	my $width  = $gdk_pixbuf->get_width;
	my $height = $gdk_pixbuf->get_height;

	$self->set_image_width($width);
	$self->set_image_height($height);

	if ( $self->thumbnail ) {
		$width  = int($width/$self->thumbnail);
		$height = int($height/$self->thumbnail);
		$gdk_pixbuf = $gdk_pixbuf->scale_simple (
			$width, $height, 1
		);
	}

	$self->set_gdk_pixbuf($gdk_pixbuf);

	1;
}


sub calculate_knobs {
	my $self = shift;
	
	my $knobs     = $self->knobs;
	my $size      = $self->knob_size;
	my $half_size = int($size/2);
	my $width     = $self->gdk_pixbuf->get_width;
	my $height    = $self->gdk_pixbuf->get_height;
	my $dx        = int($width/2.5);
	my $dy        = int($height/2.5);

	$knobs->{clip_top}->{x} = $dx - $half_size;
	$knobs->{clip_top}->{y} = $self->clip_top - $half_size;

	$knobs->{clip_bottom}->{x} = $width - $dx - $half_size;
	$knobs->{clip_bottom}->{y} = $height -  $self->clip_bottom - $half_size;

	$knobs->{clip_left}->{x} = $self->clip_left - $half_size;
	$knobs->{clip_left}->{y} = $dy - $half_size;

	$knobs->{clip_right}->{x} = $width - $self->clip_right - $half_size;
	$knobs->{clip_right}->{y} = $height - $dy - $half_size;

	1;	
}

sub draw {
	my $self = shift;

	return 1 if not $self->gdk_pixbuf;

	my $drawable = $self->drawing_area->window;
	my $black_gc = $self->drawing_area->style->black_gc;
	my $white_gc = $self->drawing_area->style->white_gc;

	return 1 if not $drawable;

	$drawable->draw_rectangle(
		$white_gc, 1, 0, 0, $self->width, $self->height
	);

	my $gdk_pixbuf = $self->gdk_pixbuf;

	$gdk_pixbuf->render_to_drawable (
		$drawable,
		$black_gc,
		0, 0, 0, 0,
		$gdk_pixbuf->get_width,
		$gdk_pixbuf->get_height,
	);

	$self->draw_clip_lines if not $self->no_clip;

	return 1;
}

sub draw_clip_lines {
	my $self = shift;
	
	my $drawable = $self->drawing_area->window;
	my $white = $self->drawing_area->style->white_gc;
	my $black = $self->drawing_area->style->black_gc;

	my $width  = $self->gdk_pixbuf->get_width;
	my $height = $self->gdk_pixbuf->get_height;

	my $clip_top    = $self->clip_top;
	my $clip_bottom = $self->clip_bottom;
	my $clip_left   = $self->clip_left;
	my $clip_right  = $self->clip_right;

	# first the lines
	$drawable->draw_line($white,
		0,          $clip_top,
		$width - 1, $clip_top
	);
	$drawable->draw_line($white,
		0,          $height - $clip_bottom - 1,
		$width - 1, $height - $clip_bottom - 1
	);
	$drawable->draw_line($white,
		$clip_left, 0,
		$clip_left, $height - 1
	);
	$drawable->draw_line($white,
		$width - $clip_right - 1, 0,
		$width - $clip_right - 1, $height - 1
	);

	# now the knobs
	my $size = $self->knob_size;
	foreach my $knob ( values %{$self->knobs} ) {
		$drawable->draw_rectangle ( $white, 1,
			$knob->{x}, $knob->{y},
			$size, $size
		);
		$drawable->draw_rectangle ( $black, 0,
			$knob->{x}, $knob->{y},
			$size-1, $size-1
		);
	}

	return 1;
}

sub button_press {
	my $self = shift;
	my ($widget, $event) = @_;

	my $x = $event->{x};
	my $y = $event->{y};

	my $width  = $self->gdk_pixbuf->get_width;
	my $height = $self->gdk_pixbuf->get_height;

	my $knob_size  = $self->knob_size;
	my $knobs      = $self->knobs;

	my ($type, $knob);
	while ( ($type, $knob) = each %{$knobs} ) {
		if ( $x >= $knob->{x} and $x < $knob->{x} + $knob_size and
		     $y >= $knob->{y} and $y < $knob->{y} + $knob_size ) {
			$self->set_dragged_knob($type);
			last;
		}
	}
	
	return 1;
}

sub motion_notify {
	my $self = shift;
	my ($widget, $event) = @_;

	my $type = $self->dragged_knob;
	return if not $type;

	$self->move_knob (
		event => $event
	);
	
	1;
}

sub button_release {
	my $self = shift;
	my ($widget, $event) = @_;

	my $type = $self->dragged_knob;
	return if not $type;

	$self->move_knob (
		event => $event
	);

	$self->set_dragged_knob(undef);

	return 1;
}

sub move_knob {
	my $self = shift;
	my %par = @_;
	my ($event) = @par{'event'};

	my $type       = $self->dragged_knob;
	my $x 	       = $event->{x};
	my $y 	       = $event->{y};
	my $grid       = $self->grid;

	my $knob_size  = $self->knob_size;

	my $width  = $self->gdk_pixbuf->get_width;
	my $height = $self->gdk_pixbuf->get_height;

	my $drawable   = $self->drawing_area->window;
	my $black_gc   = $self->drawing_area->style->black_gc;
	my $gdk_pixbuf = $self->gdk_pixbuf;

	$x = 0 if $x < 0;
	$x = $width-1 if $x >= $width;
	$y = 0 if $y < 0;
	$y = $height-1 if $y >= $height;

	$x = int(($x+1)/$grid)*$grid;
	$y = int(($y+1)/$grid)*$grid;

	my $changed = 0;
	my ($del_x, $del_y, $del_width, $del_height, $value);

	if ( $type eq 'clip_left' ) {
		if ( $x != $self->clip_left and $x < $width - $self->clip_right ) {
			$del_x = $self->clip_left;
			$del_y = 0;
			$del_width = 1;
			$del_height = $height;
			$value = $self->set_clip_left ($x);
			$changed = 1;
		}

	} elsif ( $type eq 'clip_right' ) {
		if ( $x != $width - $self->clip_right and $x > $self->clip_left ) {
			$del_x = $width - $self->clip_right - 1;
			$del_y = 0;
			$del_width = 1;
			$del_height = $height;
			$value = $self->set_clip_right ($width-$x);
			$changed = 1;
		}

	} elsif ( $type eq 'clip_top' ) {
		if ( $y != $self->clip_top and $y < $height - $self->clip_bottom ) {
			$del_x = 0;
			$del_y = $self->clip_top;
			$del_width = $width;
			$del_height = 1;
			$value = $self->set_clip_top ($y);
			$changed = 1;
		}

	} elsif ( $type eq 'clip_bottom' ) {
		if ( $y != $height - $self->clip_bottom and $y > $self->clip_top ) {
			$del_x = 0;
			$del_y = $height - $self->clip_bottom - 1;
			$del_width = $width;
			$del_height = 1;
			$value = $self->set_clip_bottom ($height-$y);
			$changed = 1;
		}
	}

	if ( $changed ) {
		my ($knob_x, $knob_y);
		$knob_x = $self->knobs->{$type}->{x};
		$knob_y	= $self->knobs->{$type}->{y};
		$knob_x = 0 if $knob_x < 0;
		$knob_y = 0 if $knob_y < 0;
		$knob_x = $width  - $knob_size - 1 if $knob_x + $knob_size + 1 > $width;
		$knob_y = $height - $knob_size - 1 if $knob_y + $knob_size + 1 > $height;
		
		$del_x = $width-1  if $del_x >= $width;
		$del_y = $height-1 if $del_y >= $height;

		$gdk_pixbuf->render_to_drawable (
			$drawable,
			$black_gc,
			$del_x, $del_y, $del_x, $del_y,
			$del_width, $del_height,
		);
		$gdk_pixbuf->render_to_drawable (
			$drawable,
			$black_gc,
			$knob_x,
			$knob_y,
			$knob_x,
			$knob_y,
			$knob_size, $knob_size,
		);
		$self->calculate_knobs;
		$self->draw_clip_lines;
		my $changed_callback = $self->changed_callback;
		&$changed_callback ( type => $type, value => $value ) if $changed_callback;
	}

	1;	
}

1;
