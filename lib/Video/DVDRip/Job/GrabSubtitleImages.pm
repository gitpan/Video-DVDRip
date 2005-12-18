# $Id: GrabSubtitleImages.pm,v 1.6 2005/10/09 12:00:40 joern Exp $

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

	if ( $buffer =~ /pic(\d+)/ ) {
		$self->set_progress_cnt ($1*10);
	}

	$self->set_operation_successful (1)
		if $buffer =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
