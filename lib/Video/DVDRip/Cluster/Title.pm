# $Id: Title.pm,v 1.31 2002/09/22 09:35:36 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Title;

use base Video::DVDRip::Title;

use Carp;
use strict;

use File::Basename;

sub frames_finished		{ shift->{frames_finished}		}
sub set_frames_finished		{ shift->{frames_finished}	= $_[1]	}

sub with_avisplit		{ shift->{with_avisplit} 		}
sub set_with_avisplit		{ shift->{with_avisplit} 	= $_[1] }

sub with_cleanup		{ shift->{with_cleanup} 		}
sub set_with_cleanup		{ shift->{with_cleanup} 	= $_[1] }

sub with_vob_remove		{ shift->{with_vob_remove} 		}
sub set_with_vob_remove		{ shift->{with_vob_remove} 	= $_[1] }

sub frames_per_chunk		{ shift->{frames_per_chunk}		}
sub set_frames_per_chunk	{ shift->{frames_per_chunk} 	= $_[1] }

sub create_vob_dir {
	my $self = shift;
	
	# no vob_dir creating here. This is done just before we
	# start transcoding to prevent from too much ssh remote
	# communication.
	
	return 1;
}

sub create_avi_dir {
	my $self = shift;

	# no avi_dir creating here. This is done just before we
	# start transcoding to prevent from too much ssh remote
	# communication.
	
	return 1;
}

#-----------------------------------------------------------------------
# Filenames of all stages
#-----------------------------------------------------------------------

sub multipass_log_dir {				# directory for multipass logs
	my $self = shift;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%s/cluster/%03d-%02d-%05d",
		$job->node->data_base_dir,
		$self->project->name,
		$self->nr,
		$job->psu,
		$job->chunk,
	);
}

sub avi_chunks_dir {				# directory for avi chunks
	my $self = shift; $self->trace_in;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%03d/chunks-psu-%02d",
		$self->project->final_avi_dir,
		$self->nr,
		$job->psu,
	);
}

sub avi_file {					# transcode output file
	my $self = shift; $self->trace_in;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%s-%03d-%05d.avi",
		$self->avi_chunks_dir,
		$self->project->name,
		$self->nr,
		$job->chunk,
	);
}

sub target_avi_audio_file {
	my $self = shift;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%03d/audio-psu-%02d/%s-%03d-audio-psu-%02d-%02d.avi",
		$self->project->final_avi_dir,
		$self->nr,
		$job->psu,
		$self->project->name,
		$self->nr,
		$job->psu,
		$job->avi_nr,
	);
}

sub audio_video_psu_dir {
	my $self = shift;

	return sprintf (
		"%s/%03d/audio-video-psu",
		$self->project->final_avi_dir,
		$self->nr,
	);
}


sub audio_video_psu_file {				# audio only file
	my $self = shift;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%s-%03d-av-psu-%02d.avi",
		$self->audio_video_psu_dir,
		$self->project->name,
		$self->nr,
		$job->psu,
	);
}

sub target_avi_file {				# final avi, merged PSUs + audio
	my $self = shift;

	return sprintf (
		"%s/%03d/%s-%03d.avi",
		$self->project->final_avi_dir,
		$self->nr,
		$self->project->name,
		$self->nr
	);
}

#-----------------------------------------------------------------------
# Commands for all Jobs
#-----------------------------------------------------------------------

sub get_transcode_command {
	my $self = shift;

	my $job       = $self->project->assigned_job or croak "No job assigned";

	my $psu       = $job->psu;
	my $chunk     = $job->chunk;
	my $chunk_cnt = $job->chunk_cnt;

	my $nav_file  = $self->vob_nav_file;

	my $command   = $self->SUPER::get_transcode_command (@_);

	# remove DVDRIP_SUCCESS
	$command =~ s/&&\s+echo\s+DVDRIP_SUCCESS//;

	# no audio options
	$command =~ s/\s-[baN]\s+[^\s]+//;

	# no -c in cluster mode
	$command =~ s/ -c \d+-\d+//;

	# no preview in cluster mode
	$command =~ s/-J\s+preview=[^\s]+//;

	# add -S and -W options for chunk selection
	$command .= " -S $psu -W $chunk,$chunk_cnt,$nav_file";

	$command =~ s/-M 2//;

	# add directory creation code
	my $avi_dir = dirname $self->avi_file;
	$command = "mkdir -m 0775 -p '$avi_dir' && $command";

	# add node specific transcode options, if configured
	$command = $self->combine_command_options (
		cmd      => "transcode",
		cmd_line => $command,
		options  => $job->node->tc_options
	) if $job->node->tc_options =~ /\S/;

	# add DVDRIP_SUCCESS
	$command .= " && echo DVDRIP_SUCCESS";

	return $command;
}

sub get_transcode_audio_command {
	my $self = shift;
	my %par = @_;
	my ($vob_nr, $target_nr) = @par{'vob_nr','target_nr'};

	my $command = $self->SUPER::get_transcode_audio_command (@_);
	$command =~ s/\s+&& echo DVDRIP_SUCCESS//;

	# add PSU selection and -W cluster parameter
	my $job = $self->project->assigned_job or croak "No job assigned";

	$command .=
		" -S ".$job->psu.
		" -W ".$job->chunk_cnt.",".$job->chunk_cnt.",".
		       $self->vob_nav_file;

	$command .= " && echo DVDRIP_SUCCESS";

	return $command;
}

sub get_merge_audio_command {
	my $self = shift;
	my %par = @_;
	my ($vob_nr, $target_nr) = @par{'vob_nr','target_nr'};

	my $job = $self->project->assigned_job or croak "No job assigned";

	my $avi_file      = $self->audio_video_psu_file;
	my $audio_file    = $self->target_avi_audio_file ( nr => $target_nr );
	my $target_file   = $avi_file;

	$target_file = $self->target_avi_file
		if $job->move_final;

	my $command =
		"avimerge".
		" -i $avi_file".
		" -p $audio_file".
		" -a $target_nr".
		" -o $avi_file.merged &&".
		" mv $avi_file.merged $target_file &&".
		" rm $audio_file &&".
		" echo DVDRIP_SUCCESS";

	return $command;
}

sub get_merge_video_audio_command {
	my $self = shift;
	
	my $job = $self->project->assigned_job or croak "No job assigned";

	my $avi_chunks_dir       = $self->avi_chunks_dir;
	my $audio_video_psu_file = $self->audio_video_psu_file;
	$audio_video_psu_file    = $self->target_avi_file
		if $job->move_final;
	my $audio_video_psu_dir  = dirname ( $audio_video_psu_file );
	my $audio_psu_file       = $self->target_avi_audio_file;

	my $chunks_mask = sprintf (
		"%s/%03d/chunks-psu-??/*",
		$self->project->final_avi_dir,
		$self->nr
	);

	my $command =
		"mkdir -m 0775 -p '$audio_video_psu_dir' && ".
		"avimerge -i $avi_chunks_dir/*".
		" -o $audio_video_psu_file ".
		" -p $audio_psu_file ".
		" && echo DVDRIP_SUCCESS";

	$command .= " && rm $avi_chunks_dir/* '$audio_psu_file'"
		if $self->with_cleanup;

	return $command;
}

sub get_merge_psu_command {
	my $self = shift;
	my %par = @_;
	my ($psu) = @par{'psu'};
	
	my $target_avi_file      = $self->target_avi_file;
	my $target_avi_dir       = dirname($target_avi_file);
	my $audio_video_psu_dir  = $self->audio_video_psu_dir;

	my $command =
		"mkdir -m 0775 -p '$target_avi_dir' && ".
		"avimerge -o '$target_avi_file' ".
		" -i $audio_video_psu_dir/*.avi 2>/dev/null";

	$command .= " && echo DVDRIP_SUCCESS";
	$command .= " && rm $audio_video_psu_dir/*.avi"
		if $self->with_cleanup;

	return $command;
}

sub get_split_command {
	my $self = shift;

	my $target_avi_file   = $self->target_avi_file;

	my $command = $self->SUPER::get_split_command;
	$command   .= " && rm '$target_avi_file'" if $self->with_cleanup;
	
	return $command;
}

sub save {
	my $self = shift;
	
	$self->project->save;
	
	1;
}

1;
