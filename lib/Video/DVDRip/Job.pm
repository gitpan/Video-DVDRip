# $Id: Job.pm,v 1.19 2005/12/26 13:57:46 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Base;

use Carp;
use strict;

# nr of the job
sub nr     { shift->{nr} }
sub set_nr { shift->{nr} = $_[1] }

# assigned Title
sub title     { shift->{title} }
sub set_title { shift->{title} = $_[1] }

# references to jobs, which must be executed successfully first
sub depends_on_jobs     { shift->{depends_on_jobs} }
sub set_depends_on_jobs { shift->{depends_on_jobs} = $_[1] }

# dependencies as a human readable string
sub dep_as_string     { shift->{dep_as_string} }
sub set_dep_as_string { shift->{dep_as_string} = $_[1] }

# state of the job: waiting, running, finished, aborted
sub state     { shift->{state} }
sub set_state { shift->{state} = $_[1] }

# timeout for feedback of job's executed command
sub timeout     { shift->{timeout} }
sub set_timeout { shift->{timeout} = $_[1] }

# grab command's output if true
sub need_output     { shift->{need_output} }
sub set_need_output { shift->{need_output} = $_[1] }

# class to use for command execution
sub pipe_class     { shift->{pipe_class} }
sub set_pipe_class { shift->{pipe_class} = $_[1] }

# actual pipe instance, if the job is running
sub pipe     { shift->{pipe} }
sub set_pipe { shift->{pipe} = $_[1] }

# true, if the user cancelled this job
sub cancelled     { shift->{cancelled} }
sub set_cancelled { shift->{cancelled} = $_[1] }

# job can set this specific error message, if something goes wrong
sub error_message     { shift->{error_message} }
sub set_error_message { shift->{error_message} = $_[1] }

# start time
sub progress_start_time     { shift->{progress_start_time} }
sub set_progress_start_time { shift->{progress_start_time} = $_[1] }

# end time
sub progress_end_time     { shift->{progress_end_time} }
sub set_progress_end_time { shift->{progress_end_time} = $_[1] }

# maximum expected progress value
sub progress_max     { shift->{progress_max} }
sub set_progress_max { shift->{progress_max} = $_[1] }

# actual progress counter
sub progress_cnt     { shift->{progress_cnt} }
sub set_progress_cnt { shift->{progress_cnt} = $_[1] }

# show fps for this job if true
sub progress_show_fps     { shift->{progress_show_fps} }
sub set_progress_show_fps { shift->{progress_show_fps} = $_[1] }

# show elapsed time for this job if true
sub progress_show_elapsed     { shift->{progress_show_elapsed} }
sub set_progress_show_elapsed { shift->{progress_show_elapsed} = $_[1] }

# percent/progress calc possible?
sub progress_show_percent     { shift->{progress_show_percent} }
sub set_progress_show_percent { shift->{progress_show_percent} = $_[1] }

# internal switch, which notes if the job did receive progress
# information from the command (progress_start_time is set on
# first data retreival)
sub progress_called     { shift->{progress_called} }
sub set_progress_called { shift->{progress_called} = $_[1] }

# job must set this to true, if command execution was successful
# (usually done in job->parse_output)
sub operation_successful     { shift->{operation_sucessful} }
sub set_operation_successful { shift->{operation_sucessful} = $_[1] }

# duration of the job
sub duration     { shift->{duration} }
sub set_duration { shift->{duration} = $_[1] }

# true, if the job aborted unexpectedly
sub job_aborted     { shift->{job_aborted} }
sub set_job_aborted { shift->{job_aborted} = $_[1] }

# this is called when the job is finished successfully
sub cb_finished     { shift->{cb_finished} }
sub set_cb_finished { shift->{cb_finished} = $_[1] }

# after finishing this is called
sub cb_next_job     { shift->{cb_next_job} }
sub set_cb_next_job { shift->{cb_next_job} = $_[1] }

# called in case of unexpected abortion
sub cb_job_aborted     { shift->{cb_job_aborted} }
sub set_cb_job_aborted { shift->{cb_job_aborted} = $_[1] }

# this is called to show the progress state
sub cb_update_progress     { shift->{cb_update_progress} }
sub set_cb_update_progress { shift->{cb_update_progress} = $_[1] }

sub last_percent_logged     { shift->{last_percent_logged} }
sub set_last_percent_logged { shift->{last_percent_logged} = $_[1] }

sub task     { shift->{task} }
sub set_task { shift->{task} = $_[1] }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $nr, $title, $cb_finished ) = @par{ 'nr', 'title', 'cb_finished' };

    my $self = bless {
        nr                    => $nr,
        title                 => $title,
        depends_on_jobs       => [],
        state                 => 'waiting',
        cb_finished           => $cb_finished,
        progress_show_elapsed => 1,
        progress_show_percent => 1,
        pipe_class            => "Video::DVDRip::GUI::Pipe",
    }, $class;

    return $self;
}

sub progress_info { shift->info }

sub start_job {
    my $self = shift;

    my $nr = $self->nr;

    $self->log( __x( "Starting job ({nr}): ", nr => $nr ) . $self->info );

    $self->init if $self->can('init');

    $self->set_state("running");
    $self->set_progress_start_time(time);

    my $pipe_class = $self->pipe_class;

    my $last_progress_update;
    my $pipe = $self->pipe_class->new(
        command      => $self->get_job_command,
        timeout      => $self->timeout,
        need_output  => $self->need_output,
        cb_line_read => sub {
            $self->line_read( $_[0], \$last_progress_update );
        },
        cb_finished => sub { $self->finish_job },
    );

    $self->set_pipe($pipe);

    $pipe->open;

    1;
}

sub line_read {
    my $self = shift;
    my ( $line, $last_progress_update_ref ) = @_;
    $self->parse_output($line);
    my $cb_update_progress = $self->cb_update_progress;
    return unless $cb_update_progress;
    return 1 if $$last_progress_update_ref == time();
    $$last_progress_update_ref = time();
    &$cb_update_progress( job => $self );
    1;
}

sub get_job_command {
    my $self = shift;

    # this is overriden by the Cluster::Job class
    # and adds remote execution stuff

    return $self->command;
}

sub finish_job {
    my $self = shift;

    if ( $self->operation_successful ) {
        $self->commit_job;
    }
    elsif ( !$self->cancelled ) {
        $self->abort_job;
    }

    1;
}

sub commit_job {
    my $self = shift;

    my $nr = $self->nr;

    my $cb_finished = $self->cb_finished;
    eval {
        $self->commit        if $self->can('commit');
        &$cb_finished($self) if $cb_finished;
    };

    if ($@) {
        $self->set_job_aborted(1);
        $self->set_error_message($@);
        $self->log("Job aborted: $@");
    }
    else {
        $self->log( __x( "Successfully finished job ({nr}): ", nr => $nr )
                . $self->info );
        $self->set_progress_cnt( $self->progress_max );
        my $cb_update_progress = $self->cb_update_progress;
        &$cb_update_progress( job => $self ) if $cb_update_progress;

    }

    $self->pipe->close;

    $self->set_progress_end_time(time);

    $self->set_duration(
        $self->format_time(
            time => $self->progress_end_time - $self->progress_start_time
        )
    );

    $self->set_state("finished");
    $self->set_pipe(undef);

    my $cb_next_job = $self->cb_next_job;
    &$cb_next_job($self) if $cb_next_job;

    1;
}

sub cancel {
    my $self = shift;

    $self->set_cancelled(1);

    $self->abort_job;

    1;
}

sub abort_job {
    my $self = shift;

    $self->pipe->cancel if $self->pipe;

    $self->set_job_aborted(1);

    $self->log( __ "Aborting job:" . " " . $self->info );

    $self->rollback if $self->can('rollback');

    my $cb_job_aborted = $self->cb_job_aborted;
    &$cb_job_aborted() if $cb_job_aborted;

    $self->set_state("aborted");
    $self->set_pipe(undef);

    1;
}

sub parse_output {
    my $self = shift;
    my ($line) = @_;

    if ( $line =~ /DVDRIP_SUCCESS/ ) {
        $self->set_operation_successful(1);
    }

    1;
}

sub progress {
    my $self = shift;

    my $state = $self->state;
    return $self->calc_progress if $state eq 'running';

    return ""
        if $state eq 'waiting'
        or $state eq 'aborted';
    return "" if not $self->duration;
    return "Duration " . $self->duration;
}

sub calc_progress {
    my $self = shift;

    my $cnt  = $self->progress_cnt;
    my $max  = $self->progress_max || 1;
    my $time = ( time - $self->progress_start_time );
    my $fps  = "";

    if ( $cnt == $max ) {
        my $text = $self->info . ": "
            . __x( "Elapsed: {time}",
            time => $self->format_time( time => $time ) );
        $time ||= 1;
        $text .= ", "
            . __x( "FPS: {fps}", fps => sprintf( "%2.1f", $cnt / $time ) )
            if $self->progress_show_fps;
        return $text;
    }

    return $self->info . " " . __ "(no progress information available)"
        if not $self->progress_show_fps
        and not $self->progress_show_percent;
    return $self->info . ": " . __ "Initializing" if $cnt == 0;

    if ( not $self->progress_called ) {
        $self->set_progress_start_time(time);
        $self->set_progress_called(1);
    }

    $fps = sprintf( ", %2.1f fps", $cnt / $time )
        if $self->progress_show_fps
        and $time;

    my $elapsed;
    $elapsed = ", "
        . __x( "elapsed {time}", time => $self->format_time( time => $time ) )
        if $self->progress_show_elapsed;

    my $info = $self->progress_info;
    $info .= ": " if $info;

    my $percent = '';
    my $eta     = '';

    if ( $self->progress_show_percent ) {
        $percent = sprintf( "%2.2f\%", $cnt / $max * 100 );
        $eta = ", ETA: "
            . $self->format_time( time => int( $time * $max / $cnt ) - $time )
            if $cnt > 50;
        my $int_percent = int( $cnt / $max * 100 );
        if ( $int_percent > $self->last_percent_logged + 10 ) {
            $int_percent = int( $int_percent / 10 ) * 10;
            $self->set_last_percent_logged($int_percent);
            $self->log( $self->info . ": "
                    . __x( "{percent} percent done.",
                    percent => $int_percent ) );
        }
    }
    else {
        $eta = ", ETA: unknown";
        $fps =~ s/, //;
    }

    return "$info$percent$fps$elapsed$eta";
}

sub progress_runtime {
    my $self = shift;

    return $self->format_time( time => time - $self->progress_start_time );
}

sub calc_dep_string {
    my $self = shift;

    $self->set_dep_as_string("none"), return
        if not @{ $self->depends_on_jobs };

    # get numbers
    my @nr = map { $_->nr } @{ $self->depends_on_jobs };
    push @nr, 99999;    # eof

    my $dep_str;
    my $first_nr = shift @nr;
    my $last_nr  = $first_nr;

    foreach my $nr (@nr) {
        $first_nr ||= $nr;
        if ( $nr > $last_nr + 1 ) {
            $dep_str .= "$first_nr-$last_nr," if $first_nr < $last_nr;
            $dep_str .= "$first_nr,"          if $first_nr == $last_nr;
            $dep_str .= "$last_nr,"           if $first_nr > $last_nr;
            $first_nr = undef;
        }
        $last_nr = $nr;
    }

    $dep_str =~ s/.99999,$//;
    $dep_str =~ s/,$//;

    $self->set_dep_as_string($dep_str);

    1;
}

sub dependency_ok {
    my $self = shift;

    foreach my $job ( @{ $self->depends_on_jobs } ) {
        return if not $job->state eq 'finished';
    }

    return 1;
}

sub get_max_disk_usage {
    my $class  = shift;
    my %par    = @_;
    my ($jobs) = @par{'jobs'};

    my $current_disk_usage = 0;
    my $max_disk_usage     = 0;

    foreach my $job ( @{$jobs} ) {

        #		print $job->type.": $current_disk_usage => ";
        $current_disk_usage += $job->get_diskspace_needed
            if $job->can('get_diskspace_needed');

        #		print "$current_disk_usage => ";
        $max_disk_usage = $current_disk_usage
            if $current_disk_usage > $max_disk_usage;
        $current_disk_usage -= $job->get_diskspace_freed
            if $job->can('get_diskspace_freed');

        #		print "$current_disk_usage\n";
    }

    return $max_disk_usage;
}

1;
