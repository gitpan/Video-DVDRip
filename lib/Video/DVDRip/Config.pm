# $Id: Config.pm,v 1.22 2002/07/15 07:27:16 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
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

sub config			{ shift->{config}			}
sub order			{ shift->{order}			}
sub presets			{ shift->{presets}			}

sub filename			{ shift->{filename}			}
sub last_saved_data		{ shift->{last_saved_data}		}

sub set_filename		{ shift->{filename}		= $_[1] }
sub set_last_saved_data		{ shift->{last_saved_data}	= $_[1] }
sub set_presets			{ shift->{presets}		= $_[1] }
sub set_order			{ shift->{order}		= $_[1] }

my %CONFIG_PARAMETER = (
	program_name => {
		type  => 'string',
		value => "dvd::rip",
	},
	main_window_width => {
		label => "Startup Window Width",
		type  => 'number',
		value => 660,
	},
	main_window_height => {
		label => "Startup Window Height",
		type  => 'number',
		value => 650,
	},
	thumbnail_factor => {
		type  => 'number',
		value => 5,
	},
	dvd_device => {
		label => "DVD Device",
		type => 'file',
		value => "/dev/dvd",
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
	base_project_dir => {
		label => "Default Data Base Directory",
		type => 'dir',
		value => "/spare/dvdrip",
	},
	cluster_master_local => {
		label => "Start Cluster Control Daemon locally",
		type  => 'switch',
		value => 1,
	},
	cluster_master_server => {
		label => "Hostname of server with Cluster Control Daemon",
		type  => 'string',
		value => "",
	},
	cluster_master_port => {
		label => "TCP Port Number of Cluster Control Daemon",
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
			"xvid","xvidcvs","fame",
			"af6","opendivx"
		],
	},
);

my @CONFIG_ORDER = qw (
	dvd_device base_project_dir
	play_dvd_command play_file_command play_stdin_command
	default_video_codec show_tooltips
	main_window_width main_window_height
	cluster_master_local cluster_master_server
	cluster_master_port  
);

sub new {
	my $type = shift;
	my %config_parameter = %CONFIG_PARAMETER;
	my @config_order     = @CONFIG_ORDER;

	my @presets = (
		Video::DVDRip::Preset->new (
			name => "nopreset",
			title => "- No Preset -",
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
			title => "Autoadjust, Big Frame, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'big',
		),
		Video::DVDRip::Preset->new (
			name => "auto_medium",
			title => "Autoadjust, Medium Frame, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'medium',
		),
		Video::DVDRip::Preset->new (
			name => "auto_small",
			title => "Autoadjust, Small Frame, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'small',
		),
		Video::DVDRip::Preset->new (
			name => "auto_big_fast",
			title => "Autoadjust, Big Frame, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'big',
		),
		Video::DVDRip::Preset->new (
			name => "auto_medium_fast",
			title => "Autoadjust, Medium Frame, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'medium',
		),
		Video::DVDRip::Preset->new (
			name => "auto_small_fast",
			title => "Autoadjust, Small Frame, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'small',
		),
		Video::DVDRip::Preset->new (
			name => "vcd_pal_43",
			title => "VCD 4:3, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 32,
			tc_clip1_right	=> 32,
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
			tc_clip1_left	=> 80,
			tc_clip1_right	=> 80,
			tc_zoom_width	=> 352,
			tc_zoom_height	=> 256,
			tc_clip2_top	=> -16,
			tc_clip2_bottom	=> -16,
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
			title => "SVCD 16:9 anamorph, PAL",
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
			tc_clip1_top	=> 20,
			tc_clip1_bottom	=> 20,
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
			tc_clip1_left	=> 16,
			tc_clip1_right	=> 16,
			tc_zoom_width	=> 352,
			tc_zoom_height	=> 208,
			tc_clip2_top	=> -16,
			tc_clip2_bottom	=> -16,
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
#		Video::DVDRip::Preset->new (
#			name => "fast_bisection",
#			title => "Fast Frame Bisection",
#			tc_clip1_top	=> 0,
#			tc_clip1_bottom	=> 0,
#			tc_clip1_left	=> 0,
#			tc_clip1_right	=> 0,
#			tc_zoom_width	=> undef,
#			tc_zoom_height	=> undef,
#			tc_clip2_top	=> 0,
#			tc_clip2_bottom	=> 0,
#			tc_clip2_left	=> 0,
#			tc_clip2_right	=> 0,
#			tc_fast_resize  => 0,
#			tc_fast_bisection => 1,
#		),
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
	
	my $filename = $self->filename;
	confess "no filename set" if not $filename;
	confess "can't read $filename" if not -r $filename;
	
	my $loaded;
	$loaded = do $filename;
	confess "can't load $filename. Perl error: $@" if $@;

	foreach my $par ( @{$self->order} ) {
		if ( exists $loaded->config->{$par} ) {
			$self->config->{$par}->{value} =
				$loaded->config->{$par}->{value};
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
	
	my $filename = $self->filename;
	confess "not filename set" if not $filename;
	
	my $data_sref = $self->get_save_data;
	
	my $fh = FileHandle->new;

	open ($fh, "> $filename") or confess "can't write $filename";
	print $fh q{# $Id: Config.pm,v 1.22 2002/07/15 07:27:16 joern Exp $},"\n";
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

1;

__END__

		Video::DVDRip::Preset->new (
			name => "169anamorph",
			title => "16:9 No Letterbox, HQ Resize",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 768,
			tc_zoom_height	=> 432,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 0,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "169anamorph_letter",
			title => "16:9 With Letterbox, HQ Resize",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 768,
			tc_zoom_height	=> 432,
			tc_clip2_top	=> 56,
			tc_clip2_bottom	=> 56,
			tc_clip2_left	=> 64,
			tc_clip2_right	=> 64,
			tc_fast_resize  => 0,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "169anamorph_fast",
			title => "16:9 No Letterbox, Fast Resize",
			tc_clip1_top	=> 4,
			tc_clip1_bottom	=> 4,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 720,
			tc_zoom_height	=> 400,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "169anamorph_letter_fast",
			title => "16:9 Letterbox, Fast Resize",
			tc_clip1_top	=> 60,
			tc_clip1_bottom	=> 60,
			tc_clip1_left	=> 40,
			tc_clip1_right	=> 40,
			tc_zoom_width	=> 640,
			tc_zoom_height	=> 320,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "43nothing",
			title => "4:3 No Letterbox, HQ Resize",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 720,
			tc_zoom_height	=> 544,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 0,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "43letter_clip",
			title => "4:3 Letterbox, HQ Resize",
			tc_clip1_top	=> 80,
			tc_clip1_bottom	=> 80,
			tc_clip1_left	=> 16,
			tc_clip1_right	=> 16,
			tc_zoom_width	=> 688,
			tc_zoom_height	=> 392,
			tc_clip2_top	=> 4,
			tc_clip2_bottom	=> 4,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 0,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "43nothing_fast",
			title => "4:3 No Letterbox, Fast Resize",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 704,
			tc_zoom_height	=> 528,
			tc_clip2_top	=> 4,
			tc_clip2_bottom	=> 4,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "43letter_clip_fast",
			title => "4:3 Letterbox, Fast Resize",
			tc_clip1_top	=> 80,
			tc_clip1_bottom	=> 80,
			tc_clip1_left	=> 16,
			tc_clip1_right	=> 16,
			tc_zoom_width	=> 688,
			tc_zoom_height	=> 392,
			tc_clip2_top	=> 4,
			tc_clip2_bottom	=> 4,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
