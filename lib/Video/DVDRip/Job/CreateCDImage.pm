# $Id: CreateCDImage.pm,v 1.2 2002/10/15 21:14:55 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::CreateCDImage;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub max_size			{ shift->{max_size}			}
sub set_max_size		{ shift->{max_size}		= $_[1]	}

sub on_the_fly			{ shift->{on_the_fly}			}
sub set_on_the_fly		{ shift->{on_the_fly}		= $_[1]	}

sub type {
	return "mkisofs";
}

sub info {
	my $self = shift;

	my $info = "Create CD image";

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$self->set_progress_show_fps ( 0 );

	if ( $title->burn_cd_type eq 'iso' ) {
		$self->set_progress_max ( 10000 );
	} else {
		$self->set_progress_max ( 0 );
		$self->set_progress_show_percent ( 0 );
	}

	1;
}

sub get_diskspace_needed {
	my $self = shift; $self->trace_in;

	return $self->max_size * 1024 + 1024;
}

sub get_diskspace_freed {
	return 0;
}

sub command {
	my $self = shift;

	return $self->title->get_create_image_command (
		on_the_fly => $self->on_the_fly
	);
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $line =~ m!(\d+(\.\d+)?)\s*\%\s+done! ) {
		$self->set_progress_cnt ($1*100);
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
