# $Id: GrabSubtitleImages.pm,v 1.5 2005/07/23 08:14:15 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::GrabSubtitleImages;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job;

use Carp;
use strict;

sub show_image_cb		{ shift->{show_image_cb}		}
sub set_show_image_cb		{ shift->{show_image_cb}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($show_image_cb) = @par{'show_image_cb'};
	
	my $self = $class->SUPER::new(@_);
	
	$self->set_show_image_cb($show_image_cb);
	
	return $self;
}

sub type {
	return "grab subtitle images";
}

sub info {
	my $self = shift;

	my $info = __"Grab subtitle images";
	$info .= " - ".__x("title #{title}", title => $self->title->nr);

	return $info;
}

sub init {
	my $self = shift;
	
	$self->set_progress_max(
		$self->title->selected_subtitle->tc_preview_img_cnt * 10
	);

	$self->set_progress_show_fps(0);

	1;
}

sub command {
	my $self = shift;

	my $title  = $self->title;
	
	my $command = $title->get_subtitle_grab_images_command;
	
	return $command;
}

sub parse_output {
	my $self = shift;
	my ($buffer) = @_;

	if ( $buffer =~ /Generating\s+image:\s+(.*pic(\d+)\.pgm)/ ) {
		$self->set_progress_cnt ($2*10);
		my $subtitle = $self->title->selected_subtitle;
		my $preview_image = $subtitle->add_preview_image (
			filename => $1,
		);
		my $show_image_cb = $self->show_image_cb;
		&$show_image_cb ($1) if $show_image_cb;
	}

	$self->set_operation_successful (1)
		if $buffer =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift;
	
	$self->title->selected_subtitle->init_preview_images;
	
	1;
}

1;
