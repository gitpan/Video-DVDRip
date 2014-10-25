# $Id: MergeAudio.pm,v 1.2 2002/09/15 15:31:10 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::MergeAudio;

# That's Perl! The job classes inherit from this class,
# which is decided at *runtime* - this way standard and
# cluster mode can share the same job execution system
# by inserting the cluster logic dynamically into the
# inheritence line... great stuff!

BEGIN {	eval "use base $Video::DVDRip::JobClass" }

use Carp;
use strict;

sub chapter			{ shift->{chapter}			}
sub vob_nr			{ shift->{vob_nr}			}
sub avi_nr			{ shift->{avi_nr}			}

sub set_chapter			{ shift->{chapter}		= $_[1]	}
sub set_vob_nr			{ shift->{vob_nr}		= $_[1]	}
sub set_avi_nr			{ shift->{avi_nr}		= $_[1]	}

sub type {
	return "merge audio";
}

sub info {
	my $self = shift;

	my $info    = "Merging audio - title #".$self->title->nr;
	my $nr      = $self->vob_nr;
	my $chapter = $self->chapter;
	
	$info .= ", audio track #$nr";
	$info .= ", chapter $chapter" if $chapter;
	
	return $info;
}

sub init {
	my $self = shift;
	
	my $title   = $self->title;
	my $chapter = $self->chapter;
		
	$self->set_progress_show_fps ( 1 );

	$self->set_progress_max ( $title->frames );

	1;
}

sub command {
	my $self = shift;

	my $title = $self->title;

	$title->set_actual_chapter ($self->chapter);

	my $command = $title->get_merge_audio_command (
		vob_nr    => $self->vob_nr,
		target_nr => $self->avi_nr,
	);

	$title->set_actual_chapter (undef);

	return $command;
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

	if ( $line =~ /\(\d+-(\d+)\)/ ) {
		$self->set_progress_cnt ($1);
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
