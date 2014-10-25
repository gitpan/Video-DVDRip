# $Id: Content.pm,v 1.16 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
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

sub read_title_listing {
	my $self = shift;
	
	my $rip_mode    = $self->project->rip_mode;
	my $data_source = $self->project->rip_data_source;

	my $title_cnt;

	# execute tcprobe to get the number of titles
	my $output = $self->system (
		command => "tcprobe -i $data_source"
	);
	
	($title_cnt) = $output =~ m!DVD\s+title\s+\d+/(\d+)!;

	# Fatal error if we can't determine the title cnt
	if ( not $title_cnt ) {
		croak "Can't determine number of titles.\n".
		      "Please put the DVD in your drive.\n".
		      "tcprobe output was:\n$output";
	}
	
	my ($nr, %titles);
	foreach my $nr ( 1..$title_cnt ) {
		$titles{$nr} = Video::DVDRip::Title->new (
			nr      => $nr,
			project => $self->project
		);
	}

	# store Title objects
	$self->set_titles (\%titles);
	
	1;
}

sub get_titles_by_nr {
	my $self = shift;
	
	$self->read_title_listing if not $self->titles;

	my @titles = sort { $a->nr <=> $b->nr } values %{$self->titles};

	return \@titles;
}

1;
