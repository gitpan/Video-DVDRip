# $Id: Project.pm,v 1.45 2005/07/23 08:14:15 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 J�rn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Project;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;

use FileHandle;
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Copy;

use Video::DVDRip::Content;

sub name			{ shift->{name}				}
sub version			{ shift->{version}			}
sub filename			{ shift->{filename}			}
sub dvd_device			{ shift->{dvd_device}			}
sub vob_dir			{ shift->{vob_dir}  			}
sub avi_dir			{ shift->{avi_dir}  			}
sub snap_dir			{ shift->{snap_dir}  			}
sub content			{ shift->{content}			}
sub last_saved_data		{ shift->{last_saved_data}		}
sub selected_title_nr		{ shift->{selected_title_nr}		}
sub rip_mode			{ shift->{rip_mode} 	       || 'rip'	}
sub dvd_image_dir		{ shift->{dvd_image_dir}		}
sub convert_message		{ shift->{convert_message}		}
sub last_selected_nb_page	{ shift->{last_selected_nb_page}	}

sub set_version			{ shift->{version}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_dvd_device		{ shift->{dvd_device}		= $_[1]	}
sub set_vob_dir			{ shift->{vob_dir}  		= $_[1]	}
sub set_avi_dir			{ shift->{avi_dir}  		= $_[1]	}
sub set_snap_dir		{ shift->{snap_dir}		= $_[1]	}
sub set_content			{ shift->{content}		= $_[1] }
sub set_last_saved_data		{ shift->{last_saved_data}	= $_[1] }
sub set_selected_title_nr	{ shift->{selected_title_nr}	= $_[1] }
sub set_rip_mode		{ shift->{rip_mode}		= $_[1]	}
sub set_dvd_image_dir		{ shift->{dvd_image_dir}	= $_[1]	}
sub set_convert_message		{ shift->{convert_message}	= $_[1]	}
sub set_last_selected_nb_page	{ shift->{last_selected_nb_page}= $_[1]	}

sub logfile {
	my $self = shift;
	return $self->snap_dir."/logfile.txt";
}

sub ifo_dir {
	my $self = shift;
	
	return sprintf ("%s/ifo", $self->snap_dir);
}

sub set_name {
	my $self = shift;
	my ($new_name) = @_;
	
	my $old_name = $self->name;

	my $project_dir = $self->config('base_project_dir');
	
	if ( $self->vob_dir eq "$project_dir/$old_name/vob" ) {
		$self->set_vob_dir("$project_dir/$new_name/vob");
	}
	     
	if ( $self->avi_dir eq "$project_dir/$old_name/avi" ) {
		$self->set_avi_dir("$project_dir/$new_name/avi");
	}

	if ( $self->snap_dir eq "$project_dir/$old_name/tmp" ) {
		$self->set_snap_dir("$project_dir/$new_name/tmp");
	}
	
	$self->{name} = $new_name;
	
	1;
}

sub new {
	my $class = shift;

	my $base_project_dir = $class->config('base_project_dir');

	my $self = bless {
		name              => "unnamed",
		filename          => "unnamed.rip",
		dvd_device	  => $class->config('dvd_device'),
		rip_mode          => "rip",
		vob_dir		  => "$base_project_dir/unnamed/vob",
		avi_dir		  => "$base_project_dir/unnamed/avi",
		snap_dir	  => "$base_project_dir/unnamed/tmp",
		content  	  => undef,
		last_saved_data   => undef,
		selected_title_nr => undef,
		version           => $Video::DVDRip::VERSION,
	}, $class;

	my $content = Video::DVDRip::Content->new ( project => $self );

	$self->set_content ($content);

	return $self;
}

sub new_from_file {
	my $class = shift;
	my %par = @_;
	my  ($filename) =
	@par{'filename'};
	
	confess "missing filename" if not $filename;
	
	my $self = bless {
		filename => $filename,
	}, $class;
	
	$self->load;
	
	$self->set_filename ($filename);
	$self->set_version ($Video::DVDRip::VERSION);

	return $self;
}

sub save {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($filename) = @par{'filename'};

	$filename ||= $self->filename;
	confess "not filename set" if not $filename;
	
	my $dir = dirname($filename);
	mkpath ([$dir], 0, 0775) unless -d $dir;

	my $data_sref = $self->get_save_data;
	
	my $fh = FileHandle->new;

	open ($fh, "> $filename") or confess "can't write $filename";
	print $fh q{# $Id: Project.pm,v 1.45 2005/07/23 08:14:15 joern Exp $},"\n";
	print $fh "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

	print $fh ${$data_sref};
	close $fh;
	
	$self->set_last_saved_data ($data_sref);

	$self->log (__x("Project file saved to '{filename}'", filename => $filename));

	my $dir = $self->snap_dir;
	if ( ! -d $dir ) {
		mkpath([$dir], 0, 0755) or die "can't create directory $dir";
		$self->log (__x("Project temporary dir '{dir}' created", dir => $dir));
	}

	1;
}

sub backup_copy {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->snap_dir."/backup.rip";
	my $last_save_data = $self->last_saved_data;
	$self->save ( filename => $filename );
	$self->set_last_saved_data($last_save_data);
	
	1;
}

sub get_save_data {
	my $self = shift; $self->trace_in;
	
	my $last_saved_data = $self->last_saved_data;
	$self->set_last_saved_data(undef);

	my $filename = $self->filename;
	$self->set_filename(undef);

	my $dd = Data::Dumper->new ( [$self], ['project'] );
	$dd->Indent(1);
	$dd->Purity(1);
	my $data = $dd->Dump;

	my $end_marker = "}, 'Video::DVDRip::Project' );\n";
	my $end_marker_quoted = quotemeta($end_marker);
	$data =~ s/$end_marker_quoted.*/$end_marker/so;

	$self->set_last_saved_data($last_saved_data);
	$self->set_filename ($filename);

	return \$data;
}

sub changed {
	my $self = shift; $self->trace_in;

	return 1 if not $self->last_saved_data;

	my $actual_data_sref = $self->get_save_data;
	my $saved_data_sref  = $self->last_saved_data;


	my $actual = join ("\n", map { $_.="," if !/,$/;$_ }
				 sort split (/\n/, $$actual_data_sref));
	my $saved  = join ("\n", map { $_.="," if !/,$/;$_ }
				 sort split (/\n/, $$saved_data_sref));

	if ( $self->debug_level ) {
		open (DBG,">/tmp/saved.txt"); print DBG $saved; close DBG;
		open (DBG,">/tmp/actual.txt"); print DBG $actual; close DBG;
	}

	return $actual ne $saved;
}

sub load {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->filename;
	croak __"no filename set" if not $filename;
	croak __x("can't read {filename}", filename => $filename) if not -r $filename;
	
	my $fh = FileHandle->new;
	open ($fh, $filename) or croak __x("can't read {filename}", filename => $filename);
	my $data;
	while (<$fh>) {
		$data .= $_;
		last if $data =~ /Video::DVDRip::Project/;
	}
	close $fh;

	croak __"File is no dvd::rip file"
		if $data !~ /This file was generated by Video::DVDRip/;

	my ($version, undef, $pre) =  $data =~ /DVDRip Version (\d+\.\d+)(_(\d+))?/;
	my ($major, $minor, $patch) = $data =~ /DVDRip Version (\d+)\.(\d+)\.(\d+)/;

	my $project;
	$project = eval($data);
	croak __x("can't load {filename}. Perl error: {error}", filename => $filename, error => $@) if $@;

	bless $project, ref($self);

	my $save_data = $project->get_save_data;

	$self->convert_from_old_version (
		project => $project,
		version => $version,
		pre     => $pre,
		major   => $major,
		minor   => $minor,
		patch   => $patch,
	);

	%{$self} = %{$project};

	$self->content->set_project ($self);
	$self->check_for_deleted_filters;

	$self->set_last_saved_data ($save_data);

	1;
}

sub get_free_diskspace {
	my $self = shift;
	my %par = @_;
	my ($kb) = @par{'kb'};

	my $dir  = $self->avi_dir;
	
	if ( not -d $dir ) {
		mkpath ( [$dir], 0, 0755);
	}
	
	my $df   = qx[ df -Pk $dir ];
	my ($free) = $df =~ /\s+\d+\s+\d+\s+(\d+)/;
	$free = int ($free/1024) if not $kb;

	return $free;
}

sub rip_data_source {
	my $self = shift; $self->trace_in;
	
	my $mode = $self->rip_mode;

	my $source;

	if ( $mode eq 'rip' or $mode eq 'dvd' ) {
		$source = $self->dvd_device;

	} elsif ( $mode eq 'dvd_image' ) {
		$source = $self->dvd_image_dir;

	}

	return $source;
}

sub dvd_mount_dir {
	my $self = shift; $self->trace_in;
	
	my $mode = $self->rip_mode;

	my $dir;

	if ( $mode eq 'rip' or $mode eq 'dvd' ) {
		$dir = $self->config('dvd_mount_point');

	} elsif ( $mode eq 'dvd_image' ) {
		$dir = $self->dvd_image_dir;

	}

	return $dir;
}

sub copy_ifo_files {
	my $self = shift;

	mkpath ( [ $self->ifo_dir  ], 0, 0755);

	my $mounted = $self->dvd_is_mounted;
	$self->mount_dvd if not $mounted;

	my @files = glob (
		$self->dvd_mount_dir.
		"/{video_ts,VIDEO_TS}/{vts,VTS}*{ifo,IFO}"
	);

	if ( not @files ) {
		$self->log (__"WARNING: no IFO files found - vobsub feature disabled.");
	}

	$self->log (__x("Copying IFO files to {dir}", dir => $self->ifo_dir));

	copy ($_, $self->ifo_dir."/".lc(basename($_))) for @files;

	$self->umount_dvd if not $mounted;

	1;
}

sub dvd_is_mounted {
	my $self = shift;
	
	return 1 if $self->rip_mode eq 'dvd_image';
	
	my $dvd_mount_point = $self->config('dvd_mount_point');

	return 1 if -d "$dvd_mount_point/video_ts";
	return 1 if -d "$dvd_mount_point/VIDEO_TS";
	return;
}

sub mount_dvd {
	my $self = shift;
	
	return 1 if $self->rip_mode eq 'dvd_image';

	my $dvd_mount_point = $self->config('dvd_mount_point');

	$self->log (__x("Mounting DVD at {mount_point}", mount_point => $dvd_mount_point));

	my $mount = qx[ mount $dvd_mount_point 2>&1 && echo DVDRIP_SUCCESS ];

	$mount =~ s/\s$//;

	croak "msg:".__x("Failed to mount DVD at {mount_point} ({mount_error})", mount_point => $dvd_mount_point, mount_error => $mount)
		if $mount !~ /DVDRIP_SUCCESS/;

	1;
}

sub umount_dvd {
	my $self = shift;
	
	return 1 if $self->rip_mode eq 'dvd_image';

	my $dvd_mount_point = $self->config('dvd_mount_point');

	my $mount = qx[ umount $dvd_mount_point 2>&1 ];

	$mount ||= "Ok";

	$self->log (__x("Umount {mount_point}: ", mount_point => $dvd_mount_point).$mount);

	1;
}

sub convert_from_old_version {
	my $self = shift;
	my %par = @_;
	my  ($project, $version, $pre, $major, $minor, $patch) =
	@par{'project','version','pre','major','minor','patch'};

	if ( $version < 0.45 or ( $version == 0.45 and
	     defined $pre and $pre < 4 ) ) {
	     	require Video::DVDRip::Convert;
	     	Video::DVDRip::Convert->convert_audio_tracks_0_45_04 (
			project => $project,
		);
	}

	if ( $version < 0.47 or ( $version == 0.47 and
	     defined $pre and $pre < 2 ) ) {
	     	require Video::DVDRip::Convert;
	     	Video::DVDRip::Convert->set_audio_bitrates_0_47_02 (
			project => $project,
		);
	}
	
	$version = $major*10000+$minor*100+$patch;

	if ( $version < 4900 ) {
	     	require Video::DVDRip::Convert;
		Video::DVDRip::Convert->convert_container_0_49_1 (
			project => $project,
		);
	}

	if ( $version < 4902 ) {
	     	require Video::DVDRip::Convert;
		Video::DVDRip::Convert->convert_0_49_2 (
			project => $project,
		);
	}
	
	1;
}

sub check_for_deleted_filters {
	my $self = shift;

	return if not $self->content->titles;

	foreach my $title ( values %{$self->content->titles} ) {
		my $selected_filters = $title->tc_filter_settings
					     ->filters;
		my @remove_filters;
		my $i = 0;
		foreach my $filter_instance ( @{$selected_filters} ) {
			eval { $filter_instance->get_filter };
			if ( $@ ) {
				print (
					__"Warning: filter '".
					$filter_instance->filter_name.
					__"' removed from title #".
					$title->nr.
					__" because this transcode installation ".
                                         "does not provide it anymore.\n"
				);
				push @remove_filters, $i;
			}
			++$i;
		}
		delete $selected_filters->[$_] for reverse @remove_filters;
	}

	1;
}

1;
