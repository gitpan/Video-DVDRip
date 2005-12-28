# $Id: Transcode.pm,v 1.3 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Task::Transcode;

use base qw( Video::DVDRip::Task );

use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use Carp;
use strict;

use Video::DVDRip::Job::TranscodeAudio;
use Video::DVDRip::Job::TranscodeVideo;
use Video::DVDRip::Job::MergeAudio;
use Video::DVDRip::Job::Mplex;
use Video::DVDRip::Job::Split;

sub subtitle_test           { shift->{subtitle_test} }
sub cb_update_video_bitrate { shift->{cb_update_video_bitrate} }
sub cb_exit_program         { shift->{cb_exit_program} }

sub set_subtitle_test           { shift->{subtitle_test}           = $_[1] }
sub set_cb_update_video_bitrate { shift->{cb_update_video_bitrate} = $_[1] }
sub set_cb_exit_program         { shift->{cb_exit_program}         = $_[1] }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $subtitle_test, $cb_update_video_bitrate, $cb_exit_program )
        = @par{ 'subtitle_test', 'cb_update_video_bitrate',
        'cb_exit_program' };

    my $self = $class->SUPER::new(@_);

    $self->set_subtitle_test($subtitle_test);
    $self->set_cb_update_video_bitrate($cb_update_video_bitrate);
    $self->set_cb_exit_program($cb_exit_program);

    return $self;
}

sub check_settings {
    my $self = shift;

    my $title    = $self->project->content->selected_title;
    my $split    = $title->tc_split;
    my $chapters = $title->get_chapters;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    if ( not $title->is_ripped ) {
        $self->message_window(
            message => __ "You first have to rip this title." );
        return 0;
    }

    if ( $title->tc_psu_core
        and ( $title->tc_start_frame or $title->tc_end_frame ) ) {
        $self->ui->message_window(
            message => __ "You can't select a frame range with psu core." );
        return 0;
    }

    if (    $title->tc_psu_core
        and $title->project->rip_mode ne 'rip' ) {
        $self->ui->message_window(
            message => __ "PSU core only available for ripped DVD's." );
        return 0;
    }

    if ( $title->tc_use_chapter_mode and not @{$chapters} ) {
        $self->ui->message_window( message => __ "No chapters selected." );
        return 0;
    }

    if ( $title->tc_use_chapter_mode and $split ) {
        $self->ui->message_window( message => __ "Splitting AVI files in\n"
                . "chapter mode makes no sense." );
        return 0;
    }

    if ( $title->get_first_audio_track == -1 ) {
        $self->ui->message_window(
            message => __ "WARNING: no target audio track #0" );
    }

    if ( keys %{ $title->get_additional_audio_tracks } ) {
        if ( $title->tc_video_codec =~ /^X?VCD$/ ) {
            $self->ui->message_window(
                message => __ "Having more than one audio track "
                    . "isn't possible on a (X)VCD." );
            return 0;
        }
        if ( $title->tc_video_codec =~ /^(X?SVCD|CVD)$/
            and keys %{ $title->get_additional_audio_tracks } > 1 ) {
            $self->ui->message_window(
                message => __ "WARNING: Having more than two audio tracks\n"
                    . "on a (X)SVCD/CVD is not standard conform. You may\n"
                    . "encounter problems on hardware players." );
        }
    }

    my $svcd_warning;
    if ( $svcd_warning = $title->check_svcd_geometry ) {
        $self->ui->message_window(
            message => __x( "WARNING {warning}\n", warning => $svcd_warning )
                . __ "You better cancel now and select the appropriate\n"
                . "preset on the Clip &amp; Zoom page.", );
    }

    return 1;
}

sub configure {
    my $self = shift;

    if ( !$self->check_settings ) {
        $self->set_configure_failed(1);
        return;
    }

    my $title = $self->project->content->selected_title;

    return $self->configure_multipass_with_vbr_audio
        if $title->has_vbr_audio
        and $title->tc_multipass
        and not $title->multipass_log_is_reused;

    my $mpeg          = $title->tc_video_codec =~ /^(X?S?VCD|CVD)$/;
    my $split         = $title->tc_split;
    my $chapters      = $title->get_chapters;
    my $subtitle_test = $self->subtitle_test;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    my $job;
    my $last_job;

    foreach my $chapter ( @{$chapters} ) {
        $job = Video::DVDRip::Job::TranscodeVideo->new( title => $title, );
        $job->set_chapter($chapter);
        $job->set_subtitle_test($subtitle_test);
        $job->set_split($split);

        if ( not $subtitle_test and $title->tc_multipass ) {
            if ( $title->multipass_log_is_reused ) {
                $self->log( __ "Skipping 1st pass as requested by "
                        . "reusing existent multipass logfile." );
            }
            else {
                $job->set_pass(1);
                $last_job = $self->add_job($job);
                $job      = Video::DVDRip::Job::TranscodeVideo->new(
                    title => $title, );
            }
            $job->set_pass(2);
            $job->set_split($split);
            $job->set_chapter($chapter);
            $job->set_depends_on_jobs( [$last_job] ) if $last_job;
            $last_job = $self->add_job($job);

        }
        else {
            $job->set_single_pass(1);
            $last_job = $self->add_job($job);
        }

        if ( $title->tc_container eq 'ogg' ) {
            $job = Video::DVDRip::Job::MergeAudio->new( title => $title, );
            $job->set_vob_nr( $title->get_first_audio_track );
            $job->set_avi_nr(0);
            $job->set_chapter($chapter);
            $job->set_subtitle_test($subtitle_test);
            $last_job = $self->add_job($job);
        }

        if ( not $subtitle_test ) {
            my $add_audio_tracks = $title->get_additional_audio_tracks;
            if ( keys %{$add_audio_tracks} ) {
                my ( $avi_nr, $vob_nr );
                foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
                    $vob_nr = $add_audio_tracks->{$avi_nr};

                    $job = Video::DVDRip::Job::TranscodeAudio->new(
                        title => $title, );
                    $job->set_vob_nr($vob_nr);
                    $job->set_avi_nr($avi_nr);
                    $job->set_chapter($chapter);
                    $last_job = $self->add_job($job);

                    if ( not $mpeg ) {
                        $job = Video::DVDRip::Job::MergeAudio->new(
                            title => $title, );
                        $job->set_vob_nr($vob_nr);
                        $job->set_avi_nr($avi_nr);
                        $job->set_chapter($chapter);
                        $last_job = $self->add_job($job);
                    }
                }
            }
        }

        if ($mpeg) {
            $job = Video::DVDRip::Job::Mplex->new( title => $title, );
            $job->set_chapter($chapter);
            $job->set_depends_on_jobs( [$last_job] );
            $job->set_subtitle_test($subtitle_test);
            $last_job = $self->add_job($job);
        }

        if ( not $subtitle_test and $split and not $mpeg ) {
            $job = Video::DVDRip::Job::Split->new( title => $title, );
            $job->set_depends_on_jobs( [$last_job] );
            $last_job = $self->add_job($job);
        }
    }

    my $final_task = $self;

    if ( $title->has_vobsub_subtitles ) {
        require Video::DVDRip::Task::CreateVobsub;
        $final_task = $self->set_next_task(
            Video::DVDRip::Task::CreateVobsub->new(
                ui      => $self->ui,
                project => $self->project,
            )
        );
    }

    $final_task->set_cb_finished(
        sub {
            return 1 if $self->cancelled or $self->errors_occured;
            return 1 if $subtitle_test;
            if ( $title->tc_execute_afterwards =~ /\S/ ) {
                system( "(" . $title->tc_execute_afterwards . ") &" );
            }
            if ( $title->tc_exit_afterwards ) {
                $title->project->save
                    if $title->tc_exit_afterwards ne 'dont_save';
                my $cb_exit_program = $self->cb_exit_program;
                &$cb_exit_program() if $cb_exit_program;
            }
            1;
        }
    );

    1;
}

sub configure_multipass_with_vbr_audio {
    my $self = shift;

    $self->log( __ "This title is transcoded with vbr audio "
            . "and video bitrate optimization." );

    my $title         = $self->project->content->selected_title;
    my $chapters      = $title->get_chapters;
    my $split         = $title->tc_split;
    my $subtitle_test = $self->subtitle_test;

    if ( not $title->tc_use_chapter_mode ) {
        $chapters = [undef];
    }

    my $bc = Video::DVDRip::BitrateCalc->new( title => $title );

    my $job;
    my $last_job;

    # 1. encode additional audio tracks
    foreach my $chapter ( @{$chapters} ) {
        my $add_audio_tracks = $title->get_additional_audio_tracks;
        if ( keys %{$add_audio_tracks} ) {
            my ( $avi_nr, $vob_nr );
            foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
                $vob_nr = $add_audio_tracks->{$avi_nr};
                $job    = Video::DVDRip::Job::TranscodeAudio->new(
                    title => $title, );
                $job->set_vob_nr($vob_nr);
                $job->set_avi_nr($avi_nr);
                $job->set_chapter($chapter);
                $job->set_bc($bc);
                $last_job = $self->add_job($job);
            }
        }
    }

    # 2. 1st pass of Video + 1st Audio track
    foreach my $chapter ( @{$chapters} ) {
        $job = Video::DVDRip::Job::TranscodeVideo->new( title => $title, );
        $job->set_bc($bc);
        $job->set_pass(1);
        $job->set_chapter($chapter);
        $job->set_depends_on_jobs( [$last_job] ) if $last_job;
        $last_job = $self->add_job($job);
    }

    # 3. after 1st pass: calculate video bitrate (real audio size known)
    $last_job->set_cb_finished(
        sub {
            $bc->calculate;
            $title->set_tc_video_bitrate( $bc->video_bitrate );
            my $cb_update_video_bitrate = $self->cb_update_video_bitrate;
            &$cb_update_video_bitrate() if $cb_update_video_bitrate;
            $self->log(
                __x("Adjusted video bitrate to {video_bitrate} "
                        . "after vbr audio transcoding",
                    video_bitrate => $bc->video_bitrate
                )
            );
            1;
        }
    );

    # 4. 2nd pass Video and merging
    foreach my $chapter ( @{$chapters} ) {

        # transcode video 2nd pass
        $job = Video::DVDRip::Job::TranscodeVideo->new( title => $title, );
        $job->set_pass(2);
        $job->set_chapter($chapter);
        $job->set_depends_on_jobs( [$last_job] );
        $last_job = $self->add_job($job);

        # merge 1st audio track
        $job = Video::DVDRip::Job::MergeAudio->new( title => $title, );
        $job->set_vob_nr( $title->get_first_audio_track );
        $job->set_avi_nr(0);
        $job->set_chapter($chapter);
        $last_job = $self->add_job($job);

        # merge add. audio tracks
        my ( $avi_nr, $vob_nr );
        my $add_audio_tracks = $title->get_additional_audio_tracks;
        foreach $avi_nr ( sort keys %{$add_audio_tracks} ) {
            $vob_nr = $add_audio_tracks->{$avi_nr};

            $job = Video::DVDRip::Job::MergeAudio->new( title => $title, );
            $job->set_vob_nr($vob_nr);
            $job->set_avi_nr($avi_nr);
            $job->set_chapter($chapter);
            $last_job = $self->add_job($job);
        }

    }

    # 5. optional splitting (non chapter mode only)
    if ($split) {
        $job = Video::DVDRip::Job::Split->new( title => $title, );
        $job->set_depends_on_jobs( [$last_job] );
        $last_job = $self->add_job($job);
    }

    # 6. vobsub
    my $final_task = $self;

    if ( $title->has_vobsub_subtitles ) {
        require Video::DVDRip::Task::CreateVobsub;
        $final_task = $self->set_next_task(
            Video::DVDRip::Task::CreateVobsub->new(
                ui      => $self->ui,
                project => $self->project,
            )
        );
    }

    $final_task->set_cb_finished(
        sub {
            return 1 if $self->cancelled or $self->errors_occured;
            return 1 if $subtitle_test;
            if ( $title->tc_execute_afterwards =~ /\S/ ) {
                system( "(" . $title->tc_execute_afterwards . ") &" );
            }
            if ( $title->tc_exit_afterwards ) {
                $title->project->save
                    if $title->tc_exit_afterwards ne 'dont_save';
                my $cb_exit_program = $self->cb_exit_program;
                &$cb_exit_program() if $cb_exit_program;
            }
            1;
        }
    );

    # 7. execute afterwards stuff
    $self->set_cb_finished(
        sub {
            return 1 if $self->cancelled or $self->errors_occured;
            if ( $title->tc_execute_afterwards =~ /\S/ ) {
                system( "(" . $title->tc_execute_afterwards . ") &" );
            }
            if ( $title->tc_exit_afterwards ) {
                $title->project->save
                    if $title->tc_exit_afterwards ne 'dont_save';
                my $cb_exit_program = $self->cb_exit_program;
                &$cb_exit_program() if $cb_exit_program;
            }
            1;
        }
    );

    1;
}

1;
