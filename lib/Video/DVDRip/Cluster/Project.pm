# $Id: Project.pm,v 1.1 2002/01/19 11:05:37 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Project;

use base Video::DVDRip::Project;

use Video::DVDRip::Cluster::Title;

use Carp;
use strict;

sub chunks		{ shift->{chunks}			}
sub chunk_cnt		{ shift->{chunk_cnt}			}
sub state		{ shift->{state}			}

sub set_state		{ shift->{state}		= $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my ($project) = @par{'project'};
	
	# bless instance with this class
	bless $project, $class;
	
	# bless all titles with the Cluster::Title class
	if ( $project->titles ) {
		foreach my $title ( values %{$project->titles} ) {
			bless $title, "Video::DVDRip::Cluster::Title";
		}
	}
	
	return $project;
}

sub set_chunk_cnt {
	my $self = shift;
	my ($chunk_cnt) = @_;

	my @chunks = ( undef ) x $chunk_cnt;

	$self->{chunk_cnt} = $chunk_cnt;
	$self->{chunks}    = \@chunks;
	
	return $chunk_cnt;
}

sub set_chunk_finished {
	my $self = shift;
	my %par = @_;
	my ($nr) = @par{'nr'};
	
	croak "Illegal chunk number $nr" if $nr >= $self->chunks_cnt;

	$self->chunks->[$nr] = time;
	
	1;
}

sub get_chunk_state {
	my $self = shift;
	my %par = @_;
	my ($nr) = @par{'nr'};
	
	croak "Illegal chunk number $nr" if $nr >= $self->chunks_cnt;
	
	return $self->chunks->[$nr];
}
