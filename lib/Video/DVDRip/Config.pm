# $Id: Config.pm,v 1.42.2.2 2003/03/03 11:59:25 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Config;

use base Video::DVDRip::Base;

use Video::DVDRip::Preset;

use strict;
use FileHandle;
use Data::Dumper;
use Carp;

my $DEFAULT_FILENAME = "$ENV{HOME}/.dvdriprc";

sub config			{ shift->{config}			}

sub order			{ shift->{order}			}
sub presets			{ shift->{presets}			}
sub filename			{ shift->{filename}			}
sub last_saved_data		{ shift->{last_saved_data}		}

sub set_order			{ shift->{order}		= $_[1] }
sub set_presets			{ shift->{presets}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_last_saved_data		{ shift->{last_saved_data}	= $_[1] }

my %CONFIG_PARAMETER = (
	program_name => {
		type  => 'string',
		value => "dvd::rip",
	},
	main_window_width => {
		label => "Startup window width",
		type  => 'number',
		value => 660,
	},
	main_window_height => {
		label => "Startup window height",
		type  => 'number',
		value => 650,
	},
	thumbnail_factor => {
		type  => 'number',
		value => 4.2,
	},
	dvd_device => {
		label => "DVD device",
		type => 'file',
		value => "/dev/dvd",
	},
	dvd_mount_point => {
		label => "DVD mount point",
		type => 'dir',
		value => "/cdrom",
	},
	writer_device => {
		label => "Writer device file",
		type => 'file',
		value => "/dev/cdrom",
	},
	eject_command => {
		label => "Eject Command",
		type => 'string',
		value => "eject",
	},
	play_dvd_command => {
		label => "DVD player command",
		type  => 'string',
		value => 'mplayer <dvd://%t -aid %(%a+128) -chapter %c -dvdangle %m>',
		presets => [
			'mplayer <dvd://%t -aid %(%a+128) -chapter %c -dvdangle %m>',
			'xine -a %a -p <dvdnav://%d:%t.%c>',
			'xine -a %a -p <d4d://i%tt0c%(%c-1)t%(%c-1)>',
		],
	},
	play_file_command => {
		label => "File player command",
		type  => 'string',
		value => 'mplayer <%f>',
		presets => [
			'xine -p <%f>',
			'mplayer <%f>',
		],
	},
	play_stdin_command => {
		label => "STDIN player command",
		type  => 'string',
		value => 'xine stdin://mpeg2 -g -pq -a %a',
		presets => [
			'mplayer -aid %(%a+128) -',
			'xine stdin://mpeg2 -g -pq -a %a',
		],
	},
	rar_command => {
		label => "rar command (for vobsub compression)",
		type  => 'string',
		value => 'rar',
		presets => [
			'rar',
		],
	},
	base_project_dir => {
		label => "Default data base directory",
		type => 'dir',
		value => "/CHANGE_ME",
	},
	dvdrip_files_dir => {
		label => "Default directory for .rip project files",
		type => 'dir',
		value => "/CHANGE_ME",
	},
	ogg_file_ext => {
		label => "OGG file extension",
		type  => 'string',
		value => 'ogm',
		presets => [
			'ogg',
			'ogm',
		],
	},
	cluster_master_local => {
		label => "Start cluster control daemon locally",
		type  => 'switch',
		value => 1,
	},
	cluster_master_server => {
		label => "Hostname of server with daemon",
		type  => 'string',
		value => "",
	},
	cluster_master_port => {
		label => "TCP port number of daemon",
		type  => 'number',
		value => 28646,
	},
	show_tooltips => {
		label => "Show tooltips",
		type  => 'switch',
		value => 1,
	},
	default_video_codec => {
		label => "Default Video Codec",
		type  => 'string',
		value => 'divx4',
		presets => [
			"SVCD","VCD","divx4","divx5",
			"xvid","xvidcvs","ffmpeg","fame",
			"af6"
		],
	},
	burn_cdrecord_device => {
		label => "cdrecord device (n,n,n)",
		type  => 'string',
		value => '0,X,0',
	},
	burn_writing_speed => {
		label => "Writing speed",
		type  => 'string',
		value => '16',
		presets => [1,2,4,8,12,16,20,24,30,40],
	},
	burn_test_mode => {
		label => "Simulate burning",
		type  => 'switch',
		value => 0,
	},
	burn_estimate_size => {
		label => "Estimate ISO size",
		type  => 'switch',
		value => 0,
		tooltip => "Estimate the size before start writing. ".
			   "Necessary for some TEAC drives for burning ".
			   "ISO discs on-the-fly",
	},
	burn_cdrecord_cmd => {
		label => "cdrecord command",
		type  => 'string',
		value => '/usr/lib/xcdroast-0.98/bin/xcdrwrap CDRECORD',
		presets => [
			'/usr/lib/xcdroast-0.98/bin/xcdrwrap CDRECORD',
			'cdrecord',
		],
	},
	burn_mkisofs_cmd => {
		label => "mkisofs command",
		type  => 'string',
		value => 'mkisofs',
		presets => ['mkisofs'],
	},
	burn_vcdimager_cmd => {
		label => "vcdimager command",
		type  => 'string',
		value => 'vcdimager',
		presets => ['vcdimager'],
	},
	burn_cdrdao_cmd => {
		label => "cdrdao command",
		type  => 'string',
		value => 'cdrdao',
		presets => ['cdrdao'],
	},
	burn_cdrdao_driver => {
		label => "cdrdao driver",
		type  => 'string',
		value => '',
		presets => [
			'', 'cdd2600','generic-mmc','generic-mmc-raw','plextor',
			'plextor-scan','ricoh-mp6200','sony-cdu920',
			'sony-cdu948','taiyo-yuden','teac-cdr55','toshiba',
			'yamaha-cdr10x',
		],
	},
	burn_cdrdao_overburn => {
		label => "Overburning",
		type  => 'switch',
		value => 1,
	},
	burn_cdrdao_eject => {
		label => "Eject disc after write",
		type  => 'switch',
		value => 1,
	},
	burn_cdrdao_buffers => {
		label => "Buffersize",
		type  => 'string',
		value => '',
	},
	dvdcss_method => {
		label => "libdvdcss method",
		type  => 'string',
		value => 'title',
		presets => ['title', 'key', 'disc'],
		onload => sub { $ENV{DVDCSS_METHOD} = $_[0] }
	},
);

my @CONFIG_ORDER = (
	"Filesystem" => [qw(
		dvd_device         dvd_mount_point
		base_project_dir   dvdrip_files_dir
		ogg_file_ext
	)],
	"Commands" => [qw(
		play_dvd_command   play_file_command
		play_stdin_command rar_command
	)],
	"CD burning" => [qw(
		writer_device        burn_cdrecord_device
		burn_cdrecord_cmd    burn_cdrdao_cmd
		burn_mkisofs_cmd     burn_vcdimager_cmd
		burn_writing_speed   burn_estimate_size
	)],
	"cdrdao options" => [qw(
		burn_cdrdao_driver   burn_cdrdao_overburn
		burn_cdrdao_eject    burn_cdrdao_buffers
	)],
	"Cluster options" => [qw(
		cluster_master_local cluster_master_server
		cluster_master_port  
	)],
	"Miscellaneous options" => [qw(
		default_video_codec  show_tooltips
		main_window_width    main_window_height
		dvdcss_method        
	)],
);

sub new {
	my $type = shift;
	my %config_parameter = %CONFIG_PARAMETER;
	my @config_order     = @CONFIG_ORDER;

	my @presets = (
		Video::DVDRip::Preset->new (
			name => "nopreset",
			title => "- No Modifications -",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> undef,
			tc_zoom_height	=> undef,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 0,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "auto_big",
			title => "Autoadjust, Big Frame Size, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'big',
		),
		Video::DVDRip::Preset->new (
			name => "auto_medium",
			title => "Autoadjust, Medium Frame Size, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'medium',
		),
		Video::DVDRip::Preset->new (
			name => "auto_small",
			title => "Autoadjust, Small Frame Size, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'small',
		),
		Video::DVDRip::Preset->new (
			name => "auto_big_fast",
			title => "Autoadjust, Big Frame Size, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'big',
		),
		Video::DVDRip::Preset->new (
			name => "auto_medium_fast",
			title => "Autoadjust, Medium Frame Size, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'medium',
		),
		Video::DVDRip::Preset->new (
			name => "auto_small_fast",
			title => "Autoadjust, Small Frame Size, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'small',
		),
		Video::DVDRip::Preset->new (
			name => "vcd_pal_43",
			title => "VCD 4:3, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 352,
			tc_zoom_height	=> 288,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "vcd_pal_16_9",
			title => "VCD 16:9, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 48,
			tc_clip1_right	=> 48,
			tc_zoom_width	=> 352,
			tc_zoom_height	=> 248,
			tc_clip2_top	=> -20,
			tc_clip2_bottom	=> -20,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "svcd_pal_16_9_4_3",
			title => "SVCD 16:9 -> 4:3 letterbox, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 480,
			tc_zoom_height	=> 432,
			tc_clip2_top	=> -72,
			tc_clip2_bottom	=> -72,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "svcd_pal",
			title => "SVCD anamorph, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 480,
			tc_zoom_height	=> 576,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "vcd_ntsc_43",
			title => "VCD 4:3, NTSC",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 352,
			tc_zoom_height	=> 240,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "vcd_ntsc_16_9",
			title => "VCD 16:9, NTSC",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 32,
			tc_clip1_right	=> 32,
			tc_zoom_width	=> 352,
			tc_zoom_height	=> 200,
			tc_clip2_top	=> -20,
			tc_clip2_bottom	=> -20,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "svcd_ntsc_16_9_4_3",
			title => "SVCD 16:9 -> 4:3 letterbox, NTSC",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 480,
			tc_zoom_height	=> 432,
			tc_clip2_top	=> -24,
			tc_clip2_bottom	=> -24,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "svcd_ntsc",
			title => "SVCD anamorph, NTSC",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 480,
			tc_zoom_height	=> 480,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
	);

	my $self = {
		config => \%config_parameter,
		order  => \@config_order,
		presets => \@presets,
	};
	
	return bless $self, $type;
}

sub load {
	my $self = shift;
	
	my $filename = $self->filename || $DEFAULT_FILENAME;
	die "can't read $filename" if not -r $filename;
	
	my $loaded;
	$loaded = do $filename;
	
	if (  $@ or ref $loaded ne 'Video::DVDRip::Config' ) {
		print
		     "\nCan't load $filename (Preferences)\n$@\n".
		     "File is probably broken.\n".
	 	     "Remove it (Note: your Preferences will be LOST)\n".
		     "and try again.\n\n";
		exit 1;
	}

	foreach my $par ( keys %{$self->config} ) {
		if ( exists $loaded->config->{$par} ) {
			$self->config->{$par}->{value} =
				$loaded->config->{$par}->{value};
		}
		if ( exists $self->config->{$par}->{onload} ) {
			my $onload = $self->config->{$par}->{onload};
			&$onload($self->get_value($par));
		}
	}
	
	1;
}

sub get_save_data {
	my $self = shift; $self->trace_in;
	
	my $last_saved_data = $self->last_saved_data;
	$self->set_last_saved_data(undef);

	my $dd = Data::Dumper->new ( [$self], ['config'] );
	$dd->Indent(1);
	my $data = $dd->Dump;

	$self->set_last_saved_data($last_saved_data);
	
	return \$data;
}

sub save {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->filename || $DEFAULT_FILENAME;
	
	my $data_sref = $self->get_save_data;
	
	my $fh = FileHandle->new;

	open ($fh, "> $filename") or die "can't write $filename";
	print $fh q{# $Id: Config.pm,v 1.42.2.2 2003/03/03 11:59:25 joern Exp $},"\n";
	print $fh "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

	print $fh ${$data_sref};
	close $fh;
	
	$self->set_last_saved_data ($data_sref);

	1;
}

sub changed {
	my $self = shift; $self->trace_in;

	return 1 if not $self->last_saved_data;

	my $actual_data_sref = $self->get_save_data;
	my $saved_data_sref  = $self->last_saved_data;
	
	my $actual = join ("\n", sort split (/\n/, $$actual_data_sref));
	my $saved  = join ("\n", sort split (/\n/, $$saved_data_sref));
	
	return $actual ne $saved;
}

sub get_value {
	my $self = shift;
	my ($name) = @_;
	my $config = $self->config;
	confess "Unknown config parameter '$name'"
		if not exists $config->{$name};
	return $config->{$name}->{value};
}

sub set_value {
	my $self = shift;
	my ($name, $value) = @_;
	my $config = $self->config;
	confess "Unknown config parameter '$name'"
		if not exists $config->{$name};

	my $db_value = $value;
	$config->{$name}->{value} = $value;

	if ( $config->{$name}->{type} eq 'list' ) {
		my $dump = Dumper($value);
		$dump =~ s/^.VAR.\s*=\s*//;
		$db_value = $dump;
	}
	
	$self->config->{$name}->{value} = $value;
	
	return $value;
}

sub entries_by_type {
	my $self = shift;
	my ($type) = @_;
	
	my %result;
	my $config = $self->config;
	my ($k, $v);
	while ( ($k, $v) = each %{$config} ) {
		$result{$k} = $v if $v->{type} eq $type;
	}
	
	return \%result;
}

sub set_temporary {
	my $self = shift;
	my ($name, $value) = @_;
	$self->config->{$name}->{value} = $value;
}

sub get_preset {
	my $self = shift;
	my %par = @_;
	my ($name) = @par{'name'};
	
	my $presets = $self->presets;
	
	foreach my $preset ( @{$presets} ) {
		return $preset if $preset->name eq $name;
	}
	
	return;
}

#---------------------------------------------------------------------
# Test methods
#---------------------------------------------------------------------

sub test_play_dvd_command   	{ _executable (@_) 	}
sub test_play_file_command  	{ _executable (@_) 	}
sub test_play_stdin_command 	{ _executable (@_) 	}
sub test_rar_command 		{ _executable (@_) 	}
sub test_dvd_device		{ _writable (@_)	}
sub test_writer_device		{ _writable (@_)	}
sub test_dvd_mount_point	{ _exists (@_)		}
sub test_base_project_dir	{ _writable (@_)	}
sub test_dvdrip_files_dir	{ _writable (@_)	}
sub test_burn_writing_speed	{ _numeric (@_)		}
sub test_burn_cdrecord_device	{ _device (@_)		}
sub test_burn_cdrecord_cmd   	{ _executable (@_) 	}
sub test_burn_cdrdao_cmd   	{ _executable (@_) 	}
sub test_burn_mkisofs_cmd   	{ _executable (@_) 	}
sub test_burn_vcdimager_cmd   	{ _executable (@_) 	}
sub test_burn_cdrdao_buffers    { _numeric_or_empty(@_) }
sub test_cluster_master_port	{ _numeric (@_)		}
sub test_dvdcss_method		{ _one_of_these (@_, ['disc','title','key'] ) }
sub test_eject_command		{ _executable (@_) 	}

sub _executable {
	my $self = shift;
	my ($name, $value) = @_;
	
	$value ||= $self->get_value ($name);
	my ($file) = split (/ /, $value);
	
	if ( not -f $file ) {
		foreach my $p ( split (/:/, $ENV{PATH}) ) {
			$file = "$p/$file",last if -x "$p/$file";
		}
	}
	
	if ( -x $file ) {
		return "$file executable : Ok";
	} else {
		return "$file not found : NOT Ok" if not -e $file;
		return "$file not executable : NOT Ok";
	}
}

sub _writable {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	return "has whitespace : NOT Ok" if $value =~ /\s/;

	if ( not -w $value ) {
		return "$value not found : NOT Ok" if not -e $value;
		return "$value not writable : NOT Ok";
	} else {
		return "$value writable : Ok";
	}
}

sub _numeric {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	if ( $value =~ /^\d+$/ ) {
		return "$value is numeric : Ok";
	} else {
		return "$value isn't numeric : NOT Ok";
	}
}

sub _numeric_or_empty {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	return "is empty : Ok" if $value eq '';
	return $self->_numeric ($name);
}

sub _device {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	if ( $value =~ /^\d+,\d+,\d+$/ ) {
		return "$value has format n,n,n : Ok";
	} else {
		return "$value has not format n,n,n : NOT Ok";
	}
}

sub _exists {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	if ( -e $value ) {
		return "$value exists : Ok";
	} else {
		return "$value doesn't exist : NOT Ok";
	}
}

sub _one_of_these {
	my $self = shift;
	my ($name, $lref) = @_;
	
	my $value = $self->get_value ($name);

	foreach my $val ( @{$lref} ) {
		return "'$value' is known : Ok" if $val eq $value;
	}

	return "'$value' unknown: NOT Ok";	
}


1;
