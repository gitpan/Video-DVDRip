# $Id: Project.pm,v 1.56 2006/07/02 13:48:36 joern Exp $

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
sub selected_title_nr		{ shift->{selected_title_nr}		}
sub rip_mode			{ shift->{rip_mode} 	       || 'rip'	}
sub convert_message		{ shift->{convert_message}		}
sub last_selected_nb_page	{ shift->{last_selected_nb_page}	}
sub created			{ my $created = shift->{created};
				  !defined($created) ? 1 : $created	}
sub selected_dvd_device         { shift->{selected_dvd_device}          }

sub set_version			{ shift->{version}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_dvd_device		{ shift->{dvd_device}		= $_[1]	}
sub set_vob_dir			{ shift->{vob_dir}  		= $_[1]	}
sub set_avi_dir			{ shift->{avi_dir}  		= $_[1]	}
sub set_snap_dir		{ shift->{snap_dir}		= $_[1]	}
sub set_content			{ shift->{content}		= $_[1] }
sub set_selected_title_nr	{ shift->{selected_title_nr}	= $_[1] }
sub set_rip_mode		{ shift->{rip_mode}		= $_[1]	}
sub set_convert_message		{ shift->{convert_message}	= $_[1]	}
sub set_last_selected_nb_page	{ shift->{last_selected_nb_page}= $_[1]	}
sub set_created			{ shift->{created}		= $_[1]	}
sub set_selected_dvd_device     { shift->{selected_dvd_device}  = $_[1] }

sub logfile {
    my $self = shift;
    return $self->snap_dir . "/logfile.txt";
}

sub ifo_dir {
    my $self = shift;

    return sprintf( "%s/ifo", $self->snap_dir );
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
        filename          => "",
        dvd_device        => $class->config('dvd_device'),
        selected_dvd_device => $class->config('dvd_device'),
        rip_mode          => "rip",
        vob_dir           => "$base_project_dir/unnamed/vob",
        avi_dir           => "$base_project_dir/unnamed/avi",
        snap_dir          => "$base_project_dir/unnamed/tmp",
        content           => undef,
        selected_title_nr => undef,
        version           => $Video::DVDRip::VERSION,
        created           => 0,
    }, $class;

    my $content = Video::DVDRip::Content->new( project => $self );

    $self->set_content($content);

    return $self;
}

sub new_from_file {
    my $class      = shift;
    my %par        = @_;
    my ($filename) = @par{'filename'};

    confess "missing filename" if not $filename;

    my $self = bless { filename => $filename, }, $class;

    $self->load;

    $self->set_filename($filename);
    $self->set_version($Video::DVDRip::VERSION);

    return $self;
}

sub save {
    my $self = shift;
    my ($filename) = @_;

    $self->set_created(1);

    $filename ||= $self->filename;
    confess "not filename set" if not $filename;

    my $dir = dirname($filename);
    mkpath( [$dir], 0, 0775 ) unless -d $dir;

    my $data_sref = $self->get_save_data_text;

    my $fh = FileHandle->new;

    open( $fh, "> $filename" ) or confess "can't write $filename";
    print $fh q{# $Id: Project.pm,v 1.56 2006/07/02 13:48:36 joern Exp $},
        "\n";
    print $fh
        "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

    print $fh ${$data_sref};
    close $fh;

    $self->log(
        __x( "Project file saved to '{filename}'", filename => $filename ) );

    my $dir = $self->snap_dir;
    if ( !-d $dir ) {
        mkpath( [$dir], 0, 0755 ) or die "can't create directory $dir";
        $self->log(
            __x( "Project temporary dir '{dir}' created", dir => $dir ) );
    }

    1;
}

sub backup_copy {
    my $self = shift;

    $self->save( filename => $self->snap_dir . "/backup.rip" );

    1;
}

sub get_save_data_text {
    my $self = shift;

    my $filename = $self->filename;
    $self->set_filename(undef);

    my $dd = Data::Dumper->new( [$self], ['project'] );
    $dd->Indent(1);
    $dd->Purity(1);
    $dd->Sortkeys(1);
    my $data = $dd->Dump;

    my $end_marker        = "}, 'Video::DVDRip::Project' );\n";
    my $end_marker_quoted = quotemeta($end_marker);
    $data =~ s/$end_marker_quoted.*/$end_marker/so;

    $self->set_filename($filename);

    return \$data;
}

sub get_save_data_binary {
    my $self = shift;

    my $filename = $self->filename;
    $self->set_filename(undef);

    require Storable;
    
    my $data = "BINFMT\n".Storable::nfreeze($self);
    
    $self->set_filename($filename);

    return \$data;
}


sub load {
    my $self = shift;

    my $filename = $self->filename;
    croak __ "no filename set" if not $filename;
    croak __x( "can't read {filename}", filename => $filename )
        if not -r $filename;

    my $fh = FileHandle->new;
    open( $fh, $filename )
        or croak __x( "can't read {filename}", filename => $filename );

    my $data;
    my $head;
    my $line = 0;
    my $bin_fmt = 0;
    while (<$fh>) {
        ++$line;
        if ( $line == 2 ) {
            die __ "File is no dvd::rip file"
                unless /This file was generated by Video::DVDRip/;
        }
        if ( $line == 4 && /BINFMT/) {
            $bin_fmt = 1;
            next;
        }
        if ( $line <= 3 ) {
            $head .= $_;
        }
        if ( $line > 3 ) {
            $data .= $_;
        }
        last if !$bin_fmt && /Video::DVDRip::Project/;
    }
    close $fh;

    my ( $version, undef, $pre )
        = $head =~ /DVDRip Version (\d+\.\d+)(_(\d+))?/;
    my ( $major, $minor, $patch )
        = $head =~ /DVDRip Version (\d+)\.(\d+)\.(\d+)/;

    my $project;
    
    if ( $bin_fmt ) {
        require Storable;
        $project = Storable::thaw($data)
            or die __"Can't load {filename}, wrong data format";
    }
    else {
        eval($data);
        croak __x(
            "can't load {filename}. Perl error: {error}",
            filename => $filename,
            error    => $@
            )
            if $@;
    }

    bless $project, ref($self);

    $self->convert_from_old_version(
        project => $project,
        version => $version,
        pre     => $pre,
        major   => $major,
        minor   => $minor,
        patch   => $patch,
    );

    %{$self} = %{$project};

    $self->content->set_project($self);
    $self->check_for_deleted_filters;

    1;
}

sub get_free_diskspace {
    my $self = shift;
    my %par  = @_;
    my ($kb) = @par{'kb'};

    my $dir = $self->avi_dir;

    if ( not -d $dir ) {
        mkpath( [$dir], 0, 0755 );
    }

    my $df = qx[ df -Pk $dir ];
    my ($free) = $df =~ /\s+\d+\s+\d+\s+(\d+)/;
    $free = int( $free / 1024 ) if not $kb;

    return $free;
}

sub rip_data_source {
    my $self = shift;
    return $self->dvd_device;
}

sub resolve_symlinks {
    my $self = shift;
    my ($file) = @_;

    require File::Spec;

    my %symlinks = ( $file => 1 );

    while ( -l $file ) {
        my $link_target = readlink($file);
        if ( !File::Spec->file_name_is_absolute($link_target) ) {
            $file =~ s!/[^/]+$!!;
            $file = File::Spec->rel2abs( $link_target, $file );
        }
        else {
            $file = $link_target;
        }
        $symlinks{$file} = 1;
    }

    return \%symlinks;
}

sub get_mount_dir_from_mtab {
    my $self = shift;
    my ( $dvd_device, $mtab_file ) = @_;

    my $symlinks_href = $self->resolve_symlinks($dvd_device);

    open( my $fh, $mtab_file )
        or die "can't read $mtab_file";

    my $mount_dir;
    while ( my $line = <$fh> ) {
        my ( $device, $dir ) = split( /\s+/, $line );
        if ( $symlinks_href->{$device} ) {
            $mount_dir = $dir;
            last;
        }
    }
    close $fh;

    return $mount_dir;
}

sub dvd_mount_point {
    my $self = shift;

    my $dvd_device = $self->dvd_device;

    my $dvd_mount_point
        = $self->get_mount_dir_from_mtab( $dvd_device,  "/etc/mtab" )
        || $self->get_mount_dir_from_mtab( $dvd_device, "/etc/fstab" );

    return $dvd_mount_point;
}

sub dvd_mount_dir {
    my $self = shift;

    return $self->dvd_mount_point;
}

sub copy_ifo_files {
    my $self = shift;

    mkpath( [ $self->ifo_dir ], 0, 0755 );

    my $mounted = $self->dvd_is_mounted;
    $self->mount_dvd if not $mounted;

    my $dvd_mount_dir = $self->dvd_mount_dir;

    my @files
        = glob( $dvd_mount_dir . "/{video_ts,VIDEO_TS}/{vts,VTS}*{ifo,IFO}" );

    if ( not @files ) {
        $self->log(
            __ "WARNING: no IFO files found - vobsub feature disabled." );
    }

    $self->log(
        __x("Copying IFO files from {src_dir} to {dir}",
            src_dir => $dvd_mount_dir,
            dir     => $self->ifo_dir
        )
    );

    copy( $_, $self->ifo_dir . "/" . lc( basename($_) ) ) for @files;

    $self->umount_dvd if not $mounted;

    1;
}

sub selected_dvd_device_list {
    my $self = shift;
    
    return $self->config_object->selected_dvd_device_list;
}

sub dvd_is_mounted {
    my $self = shift;

    my $dvd_mount_point = $self->dvd_mount_point;

    return 1 if -d "$dvd_mount_point/video_ts";
    return 1 if -d "$dvd_mount_point/VIDEO_TS";
    return;
}

sub mount_dvd {
    my $self = shift;

    return 1 if -d $self->dvd_device;

    my $dvd_mount_point = $self->dvd_mount_point;

    $self->log(
        __x("Mounting DVD at {mount_point}",
            mount_point => $dvd_mount_point
        )
    );

    my $mount = qx[ mount $dvd_mount_point 2>&1 && echo EXECFLOW_OK ];

    $mount =~ s/\s$//;

    croak "msg:"
        . __x(
        "Failed to mount DVD at {mount_point} ({mount_error})",
        mount_point => $dvd_mount_point,
        mount_error => $mount
        )
        if $mount !~ /EXECFLOW_OK/;

    1;
}

sub umount_dvd {
    my $self = shift;

    return 1 if -d $self->dvd_device;

    my $dvd_mount_point = $self->dvd_mount_point;

    my $mount = qx[ umount $dvd_mount_point 2>&1 ];

    $mount ||= "Ok";

    $self->log(
        __x( "Umount {mount_point}: ", mount_point => $dvd_mount_point )
            . $mount );

    1;
}

sub convert_from_old_version {
    my $self = shift;
    my %par  = @_;
    my ( $project, $version, $pre, $major, $minor, $patch )
        = @par{ 'project', 'version', 'pre', 'major', 'minor', 'patch' };

    if ($version < 0.45
        or (    $version == 0.45
            and defined $pre
            and $pre < 4 )
        ) {
        require Video::DVDRip::Convert;
        Video::DVDRip::Convert->convert_audio_tracks_0_45_04(
            project => $project, );
    }

    if ($version < 0.47
        or (    $version == 0.47
            and defined $pre
            and $pre < 2 )
        ) {
        require Video::DVDRip::Convert;
        Video::DVDRip::Convert->set_audio_bitrates_0_47_02(
            project => $project, );
    }

    $version = $major * 10000 + $minor * 100 + $patch;

    if ( $version < 4900 ) {
        require Video::DVDRip::Convert;
        Video::DVDRip::Convert->convert_container_0_49_1( project => $project,
        );
    }

    if ( $version < 4902 ) {
        require Video::DVDRip::Convert;
        Video::DVDRip::Convert->convert_0_49_2( project => $project, );
    }

    1;
}

sub check_for_deleted_filters {
    my $self = shift;

    return if not $self->content->titles;

    foreach my $title ( values %{ $self->content->titles } ) {
        my $selected_filters = $title->tc_filter_settings->filters;
        my @remove_filters;
        my $i = 0;
        foreach my $filter_instance ( @{$selected_filters} ) {
            eval { $filter_instance->get_filter };
            if ( $@ ) {
                print __x(
                     "Warning: filter {filter} removed from title #{nr}"
                    ." because this transcode installation doesn't"
                    ." provide it anymore",
                    filter => $filter_instance->filter_name,
                    nr     => $title->nr,
                ),"\n";
                push @remove_filters, $i;
            }
            ++$i;
        }
        delete $selected_filters->[$_] for reverse @remove_filters;
    }

    1;
}

1;
