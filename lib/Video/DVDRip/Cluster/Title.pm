# $Id: Title.pm,v 1.23 2002/04/10 21:19:12 joern Exp $

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

sub audio_avi_file {				# audio only file
	my $self = shift;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%03d/audio-only/%s-%03d-audio.avi",
		$self->project->final_avi_dir,
		$self->nr,
		$self->project->name,
		$self->nr,
	);
}

sub merged_chunks_avi_dir {			# directory for merged chunks
	my $self = shift;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%03d/chunks-merged",
		$self->project->final_avi_dir,
		$self->nr,
	);

}

sub merged_chunks_avi_file {			# merged chunks of a PSU
	my $self = shift;

	my $job = $self->project->assigned_job or croak "No job assigned";
	
	return sprintf (
		"%s/%s-%03d-merged.avi",
		$self->merged_chunks_avi_dir,
		$self->project->name,
		$self->nr,
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

	# no -c in cluster mode
	$command =~ s/ -c \d+-\d+//;

	# no preview in cluster mode
	$command =~ s/-J\s+preview=[^\s]+//;

	# add -S and -W options for chunk selection
	$command .= " -S $psu -W $chunk,$chunk_cnt,$nav_file";

	# add directory creation code
	my $avi_dir = dirname $self->avi_file;
	$command = "mkdir -m 0775 -p '$avi_dir'; $command";

	$command .= " && echo DVDRIP_SUCCESS";

	# add node specific transcode options, if configured
	$command = $self->combine_command_options (
		cmd      => "transcode",
		cmd_line => $command,
		options  => $job->node->tc_options
	) if $job->node->tc_options =~ /\S/;

	return $command;
}

sub get_transcode_audio_command {
	my $self = shift;
	
	my $job = $self->project->assigned_job or croak "No job assigned";

	my $audio_avi_file = $self->audio_avi_file;
	my $audio_avi_dir  = dirname($audio_avi_file);

	my $nice;
	$nice = "/usr/bin/nice -n ".$self->tc_nice." "
		if $self->tc_nice =~ /\S/;

	my $command =
		"mkdir -m 0775 -p '$audio_avi_dir' && ".
		$nice.
		"transcode -i ".$self->vob_dir.
		" -x null,vob -g 0x0 -y raw -u 50".
		" -a ".$self->audio_channel.
		" -b ".$self->tc_audio_bitrate.",0,".
		       $self->tc_mp3_quality.
		" -s ".$self->tc_volume_rescale.
		" -o ".$audio_avi_file.
		" && echo DVDRIP_SUCCESS";

	return $command;
}

sub get_merge_chunks_command {
	my $self = shift;
	
	my $job = $self->project->assigned_job or croak "No job assigned";

	my $merged_chunks_avi_file = $self->merged_chunks_avi_file;
	my $merged_chunks_avi_dir  = dirname ( $merged_chunks_avi_file );

	my $chunks_mask = sprintf (
		"%s/%03d/chunks-psu-??/*",
		$self->project->final_avi_dir,
		$self->nr
	);

	my $command = 
		"mkdir -m 0775 -p '$merged_chunks_avi_dir'; ".
		"avimerge -o '$merged_chunks_avi_file' -i $chunks_mask";

	$command .= " && echo DVDRIP_SUCCESS";
	
	$command .= " && rm $chunks_mask" if $self->with_cleanup;

	return $command;
}

sub get_merge_audio_command {
	my $self = shift;
	
	my $job = $self->project->assigned_job or croak "No job assigned";

	my $target_avi_file        = $self->target_avi_file;
	my $target_avi_dir         = dirname ( $target_avi_file );
	my $audio_avi_file         = $self->audio_avi_file;

	my $chunks_mask = sprintf (
		"%s/%03d/chunks-psu-??/*",
		$self->project->final_avi_dir,
		$self->nr
	);

	my $command =
		"mkdir -m 0775 -p '$target_avi_dir' && ".
		"avimerge -i $chunks_mask".
		" -o $target_avi_file ".
		" -p $audio_avi_file ".
		" && echo DVDRIP_SUCCESS";

	$command .= " && rm $chunks_mask '$audio_avi_file'"
		if $self->with_cleanup;

	return $command;
}

sub get_merge_audio_command_NO_VIDEO_MERGE {
	my $self = shift;
	
	my $job = $self->project->assigned_job or croak "No job assigned";

	my $target_avi_file        = $self->target_avi_file;
	my $target_avi_dir         = dirname ( $target_avi_file );
	my $audio_avi_file         = $self->audio_avi_file;
	my $merged_chunks_avi_file = $self->merged_chunks_avi_file;

	my $command =
		"mkdir -m 0775 -p '$target_avi_dir' && ".
		"avimerge -i $merged_chunks_avi_file".
		" -o $target_avi_file ".
		" -p $audio_avi_file ".
		" && echo DVDRIP_SUCCESS";

	$command .= " && rm '$merged_chunks_avi_file' '$audio_avi_file'"
		if $self->with_cleanup;

	return $command;
}

sub get_split_command {
	my $self = shift;

	my $target_avi_file   = $self->target_avi_file;
	my $avi_dir           = dirname($target_avi_file);

	my $command =
		$self->SUPER::get_split_command.
		" && echo DVDRIP_SUCCESS && ".
		q[perl -e 'while (<].$avi_dir.q[/*avi-0*>) {].
		q[$from=$_; s/.avi-00(..)/q{-}.sprintf(qq{%02d},$1+1).qq{.avi}/e;].
		q[rename ($from, $_);}'];
	
	$command .= " && rm '$target_avi_file'" if $self->with_cleanup;
	
	return $command;
}

sub save {
	my $self = shift;
	
	$self->project->save;
	
	1;
}

1;
