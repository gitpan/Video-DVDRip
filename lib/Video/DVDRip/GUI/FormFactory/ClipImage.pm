package Video::DVDRip::GUI::FormFactory::ClipImage;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "dvdrip_clip_image" }

sub has_additional_attrs { shift->{get_no_clip} ? [] : [qw( left right top bottom )] }

sub get_attr_left		{ shift->{attr_left}			}
sub get_attr_right		{ shift->{attr_right}			}
sub get_attr_top		{ shift->{attr_top}			}
sub get_attr_bottom		{ shift->{attr_bottom}			}
sub get_no_clip			{ shift->{no_clip}			}
sub get_file_error		{ shift->{file_error}			}

sub set_attr_left		{ shift->{attr_left}		= $_[1]	}
sub set_attr_right		{ shift->{attr_right}		= $_[1]	}
sub set_attr_top		{ shift->{attr_top}		= $_[1]	}
sub set_attr_bottom		{ shift->{attr_bottom}		= $_[1]	}
sub set_no_clip			{ shift->{no_clip}		= $_[1]	}
sub set_file_error		{ shift->{file_error}		= $_[1]	}

sub get_gtk_pixbuf		{ shift->{gtk_pixbuf}			}
sub get_gtk_v_cursor		{ shift->{gtk_v_cursor}			}
sub get_gtk_h_cursor		{ shift->{gtk_h_cursor}			}
sub get_gtk_n_cursor		{ shift->{gtk_n_cursor}			}
sub get_clip_lines		{ shift->{clip_lines}			}
sub get_line_under_cursor	{ shift->{line_under_cursor}		}
sub get_dragged_line		{ shift->{dragged_line}			}

sub set_gtk_pixbuf		{ shift->{gtk_pixbuf}		= $_[1]	}
sub set_gtk_v_cursor		{ shift->{gtk_v_cursor}		= $_[1]	}
sub set_gtk_h_cursor		{ shift->{gtk_h_cursor}		= $_[1]	}
sub set_gtk_n_cursor		{ shift->{gtk_n_cursor}		= $_[1]	}
sub set_clip_lines		{ shift->{clip_lines}		= $_[1]	}
sub set_line_under_cursor	{ shift->{line_under_cursor}	= $_[1]	}
sub set_dragged_line		{ shift->{dragged_line}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($attr_left, $attr_right, $attr_top, $attr_bottom, $no_clip) =
	@par{'attr_left','attr_right','attr_top','attr_bottom','no_clip'};

	my $self = $class->SUPER::new(%par);
	
	$self->set_attr_left   ($attr_left);
	$self->set_attr_right  ($attr_right);
	$self->set_attr_top    ($attr_top);
	$self->set_attr_bottom ($attr_bottom);
	$self->set_no_clip     ($no_clip);

	return $self;
}

sub build_widget {
	my $self = shift;

	my $gtk_drawing_area = Gtk2::DrawingArea->new;
	my $gtk_event_box    = Gtk2::EventBox->new;

	$gtk_event_box->add($gtk_drawing_area);
	$gtk_event_box->modify_bg ("normal", Gtk2::Gdk::Color->parse ("#ffffff"));

	$gtk_drawing_area->signal_connect (
		expose_event => sub { $self->draw($_[1]) },
	);

	$self->set_gtk_widget($gtk_drawing_area);
	$self->set_gtk_parent_widget($gtk_event_box);

	$self->set_gtk_n_cursor(Gtk2::Gdk::Cursor->new ('GDK_CROSSHAIR'));
	$self->set_gtk_v_cursor(Gtk2::Gdk::Cursor->new ('GDK_SB_V_DOUBLE_ARROW'));
	$self->set_gtk_h_cursor(Gtk2::Gdk::Cursor->new ('GDK_SB_H_DOUBLE_ARROW'));

	return if $self->get_no_clip;

	$gtk_event_box->set_events( ['button_press_mask','pointer-motion-mask'] );

	$gtk_event_box->signal_connect (
		button_press_event   => sub { $self->button_press($_[1]) },
	);
	$gtk_event_box->signal_connect (
		button_release_event => sub { $self->button_release($_[1]) },
	);
	$gtk_event_box->signal_connect (
		motion_notify_event  => sub { $self->motion_notify($_[1]) },
	);

	1;
}

sub object_to_widget {
	my $self = shift;

	my $filename = $self->get_object_value;
	
	if ( ! -f $filename ) {
		$self->set_file_error(1);
		$self->empty_widget;
		return 1;
	}
	
	$self->set_file_error(0);

	my $gtk_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($filename);
	$self->set_gtk_pixbuf($gtk_pixbuf);

	my $image_width  = $gtk_pixbuf->get_width;
	my $image_height = $gtk_pixbuf->get_height;

	$self->get_gtk_widget->set_size_request ($image_width+1, $image_height+1);

	$self->calc_clip_lines;
	
	if ( $self->get_dragged_line ) {
		$self->draw_clip_lines;
	} else {
		$self->draw;
	}
	
	1;
}

sub empty_widget {
	my $self = shift;
	
	my $gtk_drawing_area = $self->get_gtk_widget;
	my $gtk_pixbuf = Gtk2::Gdk::Pixbuf->new(
		'rgb',
		0, 8, 2048, 2048
	);
	$self->set_gtk_pixbuf($gtk_pixbuf);
	$self->draw;

	1;
}

sub draw {
	my $self = shift;
	my ($event) = @_;

	my $gtk_drawing_area = $self->get_gtk_widget;
	my $gtk_pixbuf       = $self->get_gtk_pixbuf;

	my $drawable   = $gtk_drawing_area->window;
	my $black_gc   = $gtk_drawing_area->style->black_gc;
	my $white_gc   = $gtk_drawing_area->style->white_gc;

	my ($x, $y, $width, $height);
	
	if ( $event ) {
		$x = $event->area->x;
		$y = $event->area->y;
		$width  = $event->area->width;
		$height = $event->area->height;
	} else {
		$x = $y = 0;
		$width  = $gtk_pixbuf->get_width;
		$height = $gtk_pixbuf->get_height;
	}

	if ( $x + $width > $gtk_pixbuf->get_width ) {
		$width = $gtk_pixbuf->get_width - $x;
	}

	if ( $y + $height > $gtk_pixbuf->get_height ) {
		$height = $gtk_pixbuf->get_height - $y;
	}

	$gtk_pixbuf->render_to_drawable (
		$drawable,
		$black_gc,
		$x, $y, $x, $y,
		$width, $height,
		"none", 0, 0
	);
	
	return if $self->get_file_error;

	$self->draw_clip_lines unless $self->get_no_clip;
	
	1;
}

sub draw_clip_lines {
	my $self = shift;
	
	my $gtk_drawing_area = $self->get_gtk_widget;
	my $gtk_pixbuf       = $self->get_gtk_pixbuf;

	my $drawable   = $gtk_drawing_area->window;
	my $white_gc   = $gtk_drawing_area->style->white_gc;

	my $clip_lines = $self->get_clip_lines;
	
	foreach my $line ( values %{$clip_lines} ) {
		$drawable->draw_line($white_gc, @{$line});
	}

	1;
}

sub clear_clip_line {
	my $self = shift;
	my ($type) = @_;

	my $gtk_drawing_area = $self->get_gtk_widget;
	my $gtk_pixbuf       = $self->get_gtk_pixbuf;

	my $drawable   = $gtk_drawing_area->window;
	my $black_gc   = $gtk_drawing_area->style->black_gc;

	my $clip_lines = $self->get_clip_lines;
	
	my $line = $clip_lines->{$type};

	my ($src_x, $src_y, $dst_x, $dst_y, $width, $height);

	if ( $type eq 'top' or $type eq 'bottom' ) {
		$src_x  = $dst_x = 0;
		$src_y  = $dst_y = $line->[1];
		$width  = $gtk_pixbuf->get_width;
		$height = 1;
		return if $src_y >= $gtk_pixbuf->get_height;
	} else {
		$src_x  = $dst_x = $line->[0];
		$src_y  = $dst_y = 0;
		$width  = 1;
		$height = $gtk_pixbuf->get_height;
		return if $src_x >= $gtk_pixbuf->get_width;
	}

	$gtk_pixbuf->render_to_drawable (
		$drawable,
		$black_gc,
		$src_x, $src_y,
		$src_x, $src_y,
		$width, $height,
		"none", 0, 0
	);

	1;
}

sub calc_clip_lines {
	my $self = shift;
	
	my $top    = $self->get_object_value($self->get_attr_top);
	my $bottom = $self->get_object_value($self->get_attr_bottom);
	my $left   = $self->get_object_value($self->get_attr_left);
	my $right  = $self->get_object_value($self->get_attr_right);

	my $gtk_pixbuf = $self->get_gtk_pixbuf;
	my $width  = $gtk_pixbuf->get_width;
	my $height = $gtk_pixbuf->get_height;

	$self->set_clip_lines ({
		top    => [ 0,             $top,              $width-1,      $top              ],
		bottom => [ 0,             $height-$bottom,   $width-1,      $height-$bottom   ],
		left   => [ $left,         0,                 $left,         $height-1         ],
		right  => [ $width-$right, 0,                 $width-$right, $height-1         ],
	});

	1;
}

sub motion_notify {
	my $self = shift;
	my ($event) = @_;
	
	return if $self->get_file_error;
	
	if ( $self->get_dragged_line ) {
		$self->move_dragged_line($event);
		return 1;
	}
	
	my $threshold = 5;
	
	my $x = $event->x;
	my $y = $event->y;
	
	my $clip_lines = $self->get_clip_lines;

	my $line_under_cursor = "";

	foreach my $type ( "top", "bottom" ) {
		my $line = $clip_lines->{$type};
		if ( $y >= $line->[1]-$threshold &&
		     $y <= $line->[1]+$threshold ) {
			$self->get_gtk_widget->window->set_cursor(
				$self->get_gtk_v_cursor,
			);
			$line_under_cursor = $type;
			last;
		}
	}
	
	foreach my $type ( "left", "right" ) {
		my $line = $clip_lines->{$type};
		if ( $x >= $line->[0]-$threshold &&
		     $x <= $line->[0]+$threshold ) {
			$self->get_gtk_widget->window->set_cursor(
				$self->get_gtk_h_cursor,
			);
			$line_under_cursor = $type;
			last;
		}
	}

	if ( not $line_under_cursor and
	     $line_under_cursor ne $self->get_line_under_cursor) {
		$self->get_gtk_widget->window->set_cursor(
			$self->get_gtk_n_cursor,
		);
	}

	$self->set_line_under_cursor($line_under_cursor);

	1;
}

sub button_press {
	my $self = shift;
	my ($event) = @_;

	my $line_under_cursor = $self->get_line_under_cursor;
	return if not $line_under_cursor;
	
	$self->set_dragged_line($line_under_cursor);
	
	1;
}

sub move_dragged_line {
	my $self = shift;
	my ($event) = @_;

	my $type = $self->get_dragged_line;
	my $x    = $event->x;
	my $y    = $event->y;

	my $gtk_pixbuf = $self->get_gtk_pixbuf;
	my $width      = $gtk_pixbuf->get_width;
	my $height     = $gtk_pixbuf->get_height;
	
	$x = $width  if $x > $width;
	$y = $height if $y > $height;

	$x = 0 if $x < 0;
	$y = 0 if $y < 0;

	my $clip_lines = $self->get_clip_lines;

	$self->clear_clip_line($type);

	$x = int($x/2)*2;
	$y = int($y/2)*2;

	if ( $type eq 'top' or $type eq 'bottom' ) {
		$clip_lines->{$type}->[1] = $y;
		$clip_lines->{$type}->[3] = $y;

	} elsif ( $type eq 'left' or $type eq 'right' ) {
		$clip_lines->{$type}->[0] = $x;
		$clip_lines->{$type}->[2] = $x;
	}
	
	$self->draw_clip_lines;
	
	1;
}

sub button_release {
	my $self = shift;
	
	my $type       = $self->get_dragged_line;
	my $clip_lines = $self->get_clip_lines;
	
	if ( $type eq 'top' ) {
		$self->set_object_value( $self->get_attr_top, $clip_lines->{$type}->[1] );
	} elsif ( $type eq 'bottom' ) {
		$self->set_object_value( $self->get_attr_bottom, $self->get_gtk_pixbuf->get_height-$clip_lines->{$type}->[1] );
	} elsif ( $type eq 'left' ) {
		$self->set_object_value( $self->get_attr_left, $clip_lines->{$type}->[0] );
	} elsif ( $type eq 'right' ) {
		$self->set_object_value( $self->get_attr_right, $self->get_gtk_pixbuf->get_width-$clip_lines->{$type}->[0] );
	}
	
	$self->set_dragged_line(undef);

	1;
}

1;
