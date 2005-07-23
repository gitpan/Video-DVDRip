package Video::DVDRip::GUI::FormFactory::SubtitlePreviews;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "dvdrip_subtitle_preview" }

sub get_gtk_hbox		{ shift->{gtk_hbox}			}
sub set_gtk_hbox		{ shift->{gtk_hbox}		= $_[1]	}

sub cleanup {
	my $self = shift;
	
	$self->SUPER::cleanup(@_);
	
	$self->set_gtk_hbox(undef);

	1;
}

sub build_widget {
	my $self = shift;

	$self->set_gtk_widget(Gtk2::VBox->new);
	
	1;
}

sub object_to_widget {
	my $self = shift;

	$self->empty_widget;
	$self->add_image( filename => $_->filename, time => $_->time )
		for @{$self->get_object_value};

	1;	
}

sub empty_widget {
	my $self = shift;
	
	my $gtk_vbox = $self->get_gtk_widget;
	my @children = $gtk_vbox->get_children;
	$gtk_vbox->remove($_) for @children;

	my $gtk_scrolled_window = Gtk2::ScrolledWindow->new;
	$gtk_scrolled_window->set (
	    hscrollbar_policy => "automatic",
	    vscrollbar_policy => "automatic",
	);

	my $gtk_event_box = Gtk2::EventBox->new;
	$gtk_event_box->modify_bg ("normal", Gtk2::Gdk::Color->parse ("#ffffff"));

	my $gtk_hbox = Gtk2::HBox->new;

	$gtk_event_box->add($gtk_hbox);
	$gtk_scrolled_window->add_with_viewport($gtk_event_box);
	
	$self->get_gtk_widget->pack_start($gtk_scrolled_window, 1, 1, 0);
	$self->set_gtk_hbox($gtk_hbox);

	$gtk_scrolled_window->show_all;

	1;
}

sub add_image {
	my $self = shift;
	my %par = @_;
	my ($filename, $time) = @par{'filename','time'};

	return 0 if ! -f $filename;
	
	my $gtk_hbox  = $self->get_gtk_hbox;
	my $gtk_image = Gtk2::Image->new_from_file($filename);
	my $gtk_vbox = Gtk2::VBox->new;
	$gtk_vbox->set ( border_width => 5 );
	$gtk_vbox->pack_start($gtk_image, 0, 1, 0);
	my $gtk_frame = Gtk2::Frame->new ($time);
	$gtk_frame->set ( border_width => 5 );
	$gtk_frame->set_label_align(0.5, 0.5);
	$gtk_frame->add($gtk_vbox);
	$gtk_frame->show_all;
	$gtk_hbox->pack_start($gtk_frame, 0, 1, 0);

	1;
}

1;
