# $Id: Content.pm,v 1.16.2.3 2003/12/16 21:26:10 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
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
		next if not $title->subtitles;
		foreach my $subtitle ( values %{$title->subtitles} ) {
			$subtitle->set_title ( $title );
		}
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

sub get_probe_title_cnt_command {
	my $self = shift;
	
	my $data_source = $self->project->rip_data_source;

	return "dr_exec tcprobe -H 10 -i $data_source && echo DVDRIP_SUCCESS";
}

sub get_titles_by_nr {
	my $self = shift;
	
	$self->read_title_listing if not $self->titles;

	my @titles = sort { $a->nr <=> $b->nr } values %{$self->titles};

	return \@titles;
}

1;
