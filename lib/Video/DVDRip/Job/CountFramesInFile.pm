# $Id: CountFramesInFile.pm,v 1.3.2.1 2003/03/03 11:40:55 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::CountFramesInFile;

use base Video::DVDRip::Job;

use Carp;
use strict;
use File::Basename;

sub files_scanned		{ shift->{files_scanned}		}
sub set_files_scanned		{ shift->{files_scanned}	= $_[1]	}

sub actual_file			{ shift->{actual_file}			}
sub set_actual_file		{ shift->{actual_file}		= $_[1]	}


sub type {
	return "count frames";
}

sub info {
	my $self = shift;

	my $info;
	if ( not $self->actual_file ) {
		$info = "Count frames in target file(s), ".
			"title #".$self->title->nr;
	} else {
		$info = "Count frames of ".basename($self->actual_file->{name}).
			", title #".$self->title->nr;
	}

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$self->set_progress_show_fps ( 0 );
	$self->set_progress_show_percent ( 0 );
	$self->set_files_scanned ( [] );
	$self->set_actual_file ( undef );

	1;
}

sub command {
	my $self = shift;

	return $self->title->get_count_frames_in_files_command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $line =~ /DVDRIP:...:([^\s]+)/ ) {
		my $info = {
			name => $1,
		};
		push @{$self->files_scanned}, $info;
		$self->set_actual_file ( $info );
	}

	if ( $line =~ /frames=\s*(\d+)/ ) {
		$self->actual_file->{frames} = $1;
		$self->log ("File ".$self->actual_file->{name}." has $1 frames.");
	}

	$self->set_operation_successful (1)
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
