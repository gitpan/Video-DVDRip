# $Id: Project.pm,v 1.33 2005/08/01 19:09:38 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Project;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Project;

use Video::DVDRip::Cluster::Title;
use Video::DVDRip::Cluster::PSU;

use Video::DVDRip::Cluster::Job::TranscodeAudio;
use Video::DVDRip::Cluster::Job::TranscodeVideo;
use Video::DVDRip::Cluster::Job::MergeVideoAudio;
use Video::DVDRip::Cluster::Job::AddAudioMerge;
use Video::DVDRip::Cluster::Job::MergePSUs;
use Video::DVDRip::Cluster::Job::Split;
use Video::DVDRip::Cluster::Job::RemoveVOBs;
use Video::DVDRip::Cluster::Job::BitrateCalc;

use Carp;
use strict;

sub id				{ shift->{id}				}
sub title			{ shift->{title}			}
sub jobs			{ shift->{jobs}				}
sub state			{ shift->{state}			}
sub assigned_job		{ shift->{assigned_job} 		}
sub start_time			{ shift->{start_time} 			}
sub end_time			{ shift->{end_time} 			}
sub runtime			{ shift->{runtime} 			}

sub set_id			{ shift->{id}			= $_[1] }
sub set_title			{ shift->{title} 		= $_[1] }
sub set_jobs			{ shift->{jobs} 		= $_[1] }
sub set_assigned_job		{ shift->{assigned_job} 	= $_[1] }
sub set_start_time		{ shift->{start_time} 		= $_[1] }
sub set_end_time		{ shift->{end_time} 		= $_[1] }
sub set_runtime			{ shift->{runtime} 		= $_[1] }

sub set_state {
	my $self = shift; $self->trace_in;
	my ($new_state) = @_;
	
	my $old_state = $self->state;
	$self->{state} = $new_state;
	
	if ( $new_state eq 'running' and not $self->start_time ) {
		$self->set_start_time(time);
	}
	
	if ( $new_state eq 'finished' and $old_state ne 'finished' ) {
		$self->set_end_time(time);
		my $runtime = $self->format_time (
			time => $self->end_time - $self->start_time
		);
		$self->set_runtime($runtime);
	}

	Video::DVDRip::Cluster::Master->get_master
				      ->emit_event("PROJECT_UPDATE", $self->id);

	$new_state;
}


sub load {
	my $self = shift; $self->trace_in;
	
	$self->SUPER::load(@_);
	
	# assign project references to contained objects
	$self->title->set_project($self);

	foreach my $job ( @{$self->jobs} ) {
		$job->set_project ($self);
		$job->set_node(undef);
	}

	1;
}

sub save {
	my $self = shift;
	
	$self->SUPER::save(@_);
	
	Video::DVDRip::Cluster::Master->get_master
				      ->emit_event("PROJECT_UPDATE", $self->id);

	1;
}

sub vob_dir {
	my $self = shift; $self->trace_in;
	
	my $job = $self->assigned_job or die "No job assigned";

	return $job->node->data_base_dir."/".
	       $self->name."/vob";
}

sub avi_dir {
	my $self = shift; $self->trace_in;
	
	my $job  = $self->assigned_job or die "No job assigned";
	my $node = $job->node;

	return $node->data_base_dir."/".
	       $self->name."/cluster/".
	       $node->name;
}

sub final_avi_dir {
	my $self = shift; $self->trace_in;
	
	my $job  = $self->assigned_job or die "No job assigned";
	my $node = $job->node;

	return $node->data_base_dir."/".
	       $self->name."/avi";
}

sub snap_dir {
	my $self = shift; $self->trace_in;

	my $job = $self->assigned_job;
	return $self->SUPER::snap_dir() if ! $job;
	my $node = $job->node;

	return $node->data_base_dir."/".
	       $self->name."/tmp";
}

sub label {
	my $self = shift; $self->trace_in;
	return $self->name." (#".$self->title->nr.")";
}

sub new {
	my $class = shift;
	my %par = @_;
	my ($project, $title_nr) = @par{'project','title_nr'};

print "title_nr=$title_nr\n";
	# bless instance with this class
	bless $project, $class;
	
	# remove content and save only the selected title
	my $title = $project->content->titles->{$title_nr};

	bless $title, "Video::DVDRip::Cluster::Title";
	$project->set_title ($title);
	$project->content->set_titles ( {} );
	
	# rebless psu
	my $psu_selected;
	foreach my $psu ( @{$title->program_stream_units} ) {
		bless $psu, "Video::DVDRip::Cluster::PSU";

		# PSU selection is currently DISABLED,
		# so all PSUs are always selected
		if ( 1 or $psu->frames >= 1000 ) {
			$psu->set_selected(1);
			$psu_selected = 1;
		}
	}
	
	# select all psu if none was selected
	if ( not $psu_selected ) {
		$_->set_selected(1) for @{$title->program_stream_units};
	}
	
	# initialize project title parameters
	$project->title->set_with_avisplit(1);
	$project->title->set_with_cleanup(1);
	$project->title->set_frames_per_chunk(10000);
	
	# make a job plan
	$project->create_job_plan;
	
	return $project;
}

sub create_job_plan {
	my $self = shift; $self->trace_in;

	$self->log (__"Creating job plan");

	my $title     = $self->title;
	my $multipass = $title->tc_multipass;

	my @pass = ( 1 );
	push @pass, 2 if $multipass;

	my (@jobs, $job, $last_job);
	my @depend_merge_psu;

	my $nr = 1;
	my $frames_per_chunk = $title->frames_per_chunk || 10000;

	# This array takes all video transcode jobs: 2nd pass or single pass.
	# In case of vbr audio these jobs depend on all audio jobs, because
	# bitrate calculation is done afterwards.
	my @tc_video_jobs;
	
	# The bitrate calculation job depends on all audio jobs.
	my @tc_audio_jobs;

	my ($bc, $bc_job);

	if ( $title->has_vbr_audio ) {
		$bc = Video::DVDRip::BitrateCalc->new ( title => $title );
		$job = Video::DVDRip::Cluster::Job::BitrateCalc->new ( nr => $nr++ );
		push @jobs, $job;
		$job->set_project ($self);
		$job->set_bc ($bc);
		$job->set_depends_on_jobs ( \@tc_audio_jobs );
		$bc_job = $job;
	}

	# first we have to do some work per psu
	foreach my $psu ( @{$title->program_stream_units} ) {
		next if not $psu->selected;

		# calculate chunk cnt of this psu
		my @depend_merge_chunk;
		my $chunk_cnt = int($psu->frames / $frames_per_chunk);
		my $nodes_cnt =
			Video::DVDRip::Cluster::Master->get_master
						      ->get_online_nodes_cnt + 1;

		$chunk_cnt = $nodes_cnt if $chunk_cnt < $nodes_cnt;
		$chunk_cnt = 2          if $chunk_cnt < 2;

		$psu->set_chunk_cnt ($chunk_cnt);

		# first an audio processing job
		my $vob_nr = $title->get_first_audio_track || 0;
		my $avi_nr = $title->audio_tracks->[$vob_nr]->tc_target_track;
		
		$job = Video::DVDRip::Cluster::Job::TranscodeAudio->new ( nr => $nr++ );
		push @jobs, $job;
		$job->set_project ($self);
		$job->set_psu ( $psu->nr );
		$job->set_chunk_cnt ($chunk_cnt);
		$job->set_prefer_local_access (1);
		$job->set_vob_nr ($vob_nr);
		$job->set_avi_nr ($avi_nr);
		$job->set_bc ($bc);
		push @depend_merge_chunk, $job;
		push @tc_audio_jobs, $job;

		# add transcode jobs for each chunk
		for (my $i=0; $i < $chunk_cnt; ++$i ) {
			# one job for each pass
			foreach my $pass ( @pass ) {
				$job = Video::DVDRip::Cluster::Job::TranscodeVideo->new ( nr => $nr++ );
				push @jobs, $job;
				$job->set_project ($self);
				$job->set_pass ($pass);
				$job->set_chunk ($i);
				$job->set_chunk_cnt ($chunk_cnt);
				$job->set_psu ($psu->nr);

				if ( not $multipass or $pass == 2 ) {
					push @tc_video_jobs, $job;
					push @depend_merge_chunk, $job;
				}

				if ( $pass == 2 ) {
					if ( $bc_job ) {
						$job->set_depends_on_jobs ( [ $bc_job, $last_job ] );
					} else {
						$job->set_depends_on_jobs ( [ $last_job ] );
					}
				} else {
					if ( $bc_job ) {
						$job->set_depends_on_jobs ( [ $bc_job ] );
					}
				}

				$last_job = $job;
			}
		}
		
		# add a merge job for this psu
		$job = Video::DVDRip::Cluster::Job::MergeVideoAudio->new ( nr => $nr++ );
		push @jobs, $job;
		$job->set_project ($self);
		$job->set_psu ( $psu->nr );
		$job->set_prefer_local_access (1);
		$job->set_depends_on_jobs ( \@depend_merge_chunk );
		$last_job = $job;
		
		my $merge_video_audio_job = $job;

		# ogg audio merging isn't done with the video/audio merge job above
		if ( $title->is_ogg ) {
			$job = Video::DVDRip::Cluster::Job::AddAudioMerge->new ( nr => $nr++ );
			push @jobs, $job;
			my $vob_nr = $title->get_first_audio_track;
			$job->set_avi_nr ( $title->audio_tracks->[$vob_nr]->tc_target_track );
			$job->set_vob_nr ( $vob_nr );
			$job->set_project ($self);
			$job->set_psu ( $psu->nr );
			$job->set_prefer_local_access (1);
			$job->set_depends_on_jobs ( [ $last_job ] );
			$last_job = $job;
			$merge_video_audio_job = $job;
		}

		# now evtl. add. audio tracks
		my $add_audio_tracks = $title->get_additional_audio_tracks;
		if ( keys %{$add_audio_tracks} ) {
			my ($avi_nr, $vob_nr);
			while ( ($avi_nr, $vob_nr) = each %{$add_audio_tracks} ) {

				$job = Video::DVDRip::Cluster::Job::TranscodeAudio->new ( nr => $nr++ );
				push @jobs, $job;
				push @tc_audio_jobs, $job;
				$job->set_project ($self);
				$job->set_psu ( $psu->nr );
				$job->set_chunk_cnt ($chunk_cnt);
				$job->set_prefer_local_access (1);
				$job->set_vob_nr ($vob_nr);
				$job->set_avi_nr ($avi_nr);
				$job->set_bc ($bc);
				$job->set_depends_on_jobs ( [] );
				$last_job = $job;

				$job = Video::DVDRip::Cluster::Job::AddAudioMerge->new ( nr => $nr++ );
				push @jobs, $job;
				$job->set_avi_nr ( $avi_nr );
				$job->set_vob_nr ( $vob_nr );
				$job->set_project ($self);
				$job->set_psu ( $psu->nr );
				$job->set_prefer_local_access (1);
				$job->set_depends_on_jobs ( [$merge_video_audio_job, $last_job] );
				$last_job = $job;
			}
		}

		# Push the last job of this PSU to the psu array.
		# If there are more than 1 PSU, these must be merged later.
		push @depend_merge_psu, $last_job;
	}
	
	# do we need merging of psu AVIs?
	if ( @depend_merge_psu > 1 ) {
		$job = Video::DVDRip::Cluster::Job::MergePSUs->new ( nr => $nr++ );
		push @jobs, $job;
		$job->set_project ($self);
		$job->set_depends_on_jobs ( \@depend_merge_psu );
		$job->set_prefer_local_access (1);
		$last_job = $job;
	} else {
		$last_job->set_move_final(1) if $last_job;
	}
	
	# finally split the AVI if requested
	if ( $title->with_avisplit ) {
		$job = Video::DVDRip::Cluster::Job::Split->new ( nr => $nr++ );
		push @jobs, $job;
		$job->set_project ($self);
		$job->set_prefer_local_access (1);
		if ( @depend_merge_psu > 1 ) {
			$job->set_depends_on_jobs ( [ $last_job ] );
		} else {
			$job->set_depends_on_jobs ( \@depend_merge_psu );
		}
		$last_job = $job;
	}
	
	# remove VOB files afterwards?
	if ( $title->with_vob_remove ) {
		$job = Video::DVDRip::Cluster::Job::RemoveVOBs->new ( nr => $nr++ );
		push @jobs, $job;
		$job->set_project ($self);
		$job->set_depends_on_jobs ( [ $last_job ] );
		$last_job = $job;
	}
	
	# calc dep strings
	$_->calc_dep_string foreach @jobs;

	# store job plan
	$self->set_jobs ( \@jobs );

	Video::DVDRip::Cluster::Master->get_master
				      ->emit_event("JOB_PLAN_UPDATE", $self->id);

	1;
}

sub get_save_data {
	my $self = shift; $self->trace_in;
	
	# don't save current job assignement
	my $job = $self->assigned_job;
	$self->set_assigned_job(undef);
	
	my @pipes;
	foreach my $job ( @{$self->jobs} ) {
		push @pipes, $job->pipe;
		$job->set_pipe(undef);
	}
	
	# get save data by calling super method
	my $data = $self->SUPER::get_save_data;
	
	# restore current job assignment
	$self->set_assigned_job($job);

	foreach my $job ( @{$self->jobs} ) {
		$job->set_pipe( shift @pipes );
	}

	return $data;
}

sub progress {
	my $self = shift; $self->trace_in;
	
	return "Duration: ".$self->runtime if $self->state eq 'finished';
	
	my $sum;
	my $finished = 0;
	my $running  = 0;
	my $waiting  = 0;

	foreach my $job ( @{$self->jobs} ) {
		++$sum;
		++$finished if $job->state eq 'finished';
		++$running  if $job->state eq 'running';
		++$waiting  if $job->state eq 'waiting' or
			       $job->state eq 'aborted';
	}
	
	return "Jobs: run=$running wait=$waiting fin=$finished sum=$sum";
}

sub jobs_list {
	my $self = shift; $self->trace_in;
	
	my @jobs;
	foreach my $job ( @{$self->jobs} ) {
		push @jobs, [
			$job->id,
			$job->nr,
			$job->info,
			$job->dep_as_string,
			$job->state,
			$job->progress,
		];
	}
	
	return \@jobs;
}

sub determine_state {
	my $self = shift; $self->trace_in;
	
	return if $self->state eq 'not scheduled';

	my $state = 'finished';

	foreach my $job ( @{$self->jobs} ) {
		if ( $job->state eq 'running' ) {
			$state = 'running';
			last;
		}
		if ( $job->state eq 'waiting' or
		     $job->state eq 'aborted' ) {
			$state = 'waiting';
		}
	}
	
	$self->set_state ($state);
	
	1;		
}

sub reset_jobs {
	my $self = shift; $self->trace_in;
	
	foreach my $job ( @{$self->jobs} ) {
		$job->set_state ('waiting') if $job->state eq 'running';
		$job->set_node (undef);
	}
	
	1;
}

sub get_job_by_id {
	my $self = shift; $self->trace_in;
	my ($job_id) = @_;

	foreach my $job ( @{$self->jobs} ) {
		return $job if $job->id == $job_id;
	}
	
	croak "Can't find job with id=$job_id";
}

sub get_dependent_jobs {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($job) = @par{'job'};
	
	# get direct dependent jobs
	my @dep_jobs;
	foreach my $j ( @{$self->jobs} ) {
		foreach my $dj ( @{$j->depends_on_jobs} ) {
			if ( $dj->id == $job->id ) {
				push @dep_jobs, $j;
				last;
			}
		}
	}

	# go into recursion to find the jobs, which
	# depend on the direct dependend jobs
	foreach my $j ( @dep_jobs ) {
		my $j_dep_jobs = $self->get_dependent_jobs ( job => $j );
		push @dep_jobs, @{$j_dep_jobs};
	}

	return \@dep_jobs;
}

sub reset_job {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($job_id) = @par{'job_id'};
	
	my $job = $self->get_job_by_id ($job_id);
	return if $job->state ne 'finished' and
		  $job->state ne 'aborted';
	
	my $dep_jobs = $self->get_dependent_jobs ( job => $job );

	# check if all dependent jobs aren't running
	foreach my $dep_job ( @{$dep_jobs} ) {
		return if $dep_job->state eq 'running';
	}
	
	# now reset all dependent jobs after resetting the
	# parent job
	$job->set_state ('waiting');

	foreach my $dep_job ( @{$dep_jobs} ) {
		$dep_job->set_state ('waiting');
	}

	# determine project state
	$self->determine_state;

	$self->save;

	Video::DVDRip::Cluster::Master->get_master->job_control;

	1;	
}

1;
