# $Id: Content.pm,v 1.8 2001/11/24 21:46:30 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Content;

use base Video::DVDRip::Base;

use Video::DVDRip::Title;

use Carp;
use strict;

sub project		{ shift->{project}		}
sub titles		{ shift->{titles}  		} # href/undef

sub set_titles		{ shift->{titles}	= $_[1] }

sub set_project	{
	my $self = shift;
	my ($project) = @_;

	$self->{project} = $project;
	
	return if not $self->titles;

	foreach my $title ( values %{$self->titles} ) {
		$title->set_project ($project);
	}
	
	return $project;
}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($project) =
	@par{'project'};

	my $self = {
		project => $project,
		titles  => undef,
	};
	
	return bless $self, $class;
}

sub read_title_listing {
	my $self = shift;
	
	my $mount_point = $self->project->mount_point;

	# try mounting the DVD
	my $rc = eval {
		$self->system (
			command   => "mount $mount_point",
			return_rc => 1,
		);
	};
	
	# try to find VIDEO_TS folder
	my $video_ts = -d "$mount_point/VIDEO_TS" ?
			"$mount_point/VIDEO_TS" : "$mount_point/video_ts";

	if ( not -d $video_ts ) {
		croak 	"can't find VIDEO_TS/video_ts folder in ".
			"directory '$mount_point'";
	}
	
	# read directory listing
	my @files = grep /VTS.*[^0]\.VOB.*$/i, glob ("$video_ts/*");

	# analyze files and create according Title objects
	my $title;
	my %titles;
	my $nr;
	foreach my $file ( @files ) {
		$file =~ /(VTS_(\d+)_\d+\.VOB.*$)/i;
		$nr = 0+$2;
		$title = $titles{$nr};
		$title ||= Video::DVDRip::Title->new (
			nr => $nr,
			project => $self->project
		);
		$titles{$nr} ||= $title;
		$title->add_vob ( file => $file );
	}

	# story Title objects
	$self->set_titles (\%titles);
	
	# if we mounted the DVD successfully, we umount it here
	# (as it was before)
	if ( $rc == 0 ) {
		$self->system (
			command => "umount $mount_point",
		);
	}
	
	1;
}

sub get_titles_by_size {
	my $self = shift;
	
	$self->read_title_listing if not $self->titles;

	my @titles = sort { $b->size <=> $a->size } values %{$self->titles};

	return \@titles;
}

1;
