# $Id: Config.pm,v 1.6 2002/01/03 17:40:00 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
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

sub new {
	my $type = shift;

	my $self = {
		config => {
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
			dvd_mount_point => {
				label => "DVD Mount Point Directory",
				type => 'dir',
				value => "/media/dvd",
			},
			base_project_dir => {
				label => "Default Data Base Directory",
				type => 'dir',
				value => "/spare/dvdrip",
			},
		},
		order => [qw(
			dvd_device dvd_mount_point base_project_dir
			main_window_width main_window_height
		)],
		presets => [
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
			),
			Video::DVDRip::Preset->new (
				name => "169anamorph",
				title => "16:9 Anamorph Encoding, No Letterbox",
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
			),
			Video::DVDRip::Preset->new (
				name => "169anamorph_letter",
				title => "16:9 Anamorph Encoding, With Letterbox",
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
			),
			Video::DVDRip::Preset->new (
				name => "43nothing",
				title => "4:3 No Zoom, No Clipping",
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
			),
			Video::DVDRip::Preset->new (
				name => "43letter_clip",
				title => "4:3 Letterbox, With Clipping",
				tc_clip1_top	=> 80,
				tc_clip1_bottom	=> 80,
				tc_clip1_left	=> 16,
				tc_clip1_right	=> 16,
				tc_zoom_width	=> undef,
				tc_zoom_height	=> undef,
				tc_clip2_top	=> 0,
				tc_clip2_bottom	=> 0,
				tc_clip2_left	=> 0,
				tc_clip2_right	=> 0,
				tc_fast_resize  => 0,
			),
			Video::DVDRip::Preset->new (
				name => "169anamorph_fast",
				title => "16:9 Anam. Enc., No Letterbox, Fast Resize",
				tc_clip1_top	=> 0,
				tc_clip1_bottom	=> 0,
				tc_clip1_left	=> 8,
				tc_clip1_right	=> 8,
				tc_zoom_width	=> 704,
				tc_zoom_height	=> 416,
				tc_clip2_top	=> 0,
				tc_clip2_bottom	=> 0,
				tc_clip2_left	=> 0,
				tc_clip2_right	=> 0,
				tc_fast_resize  => 1,
			),
			Video::DVDRip::Preset->new (
				name => "169anamorph_letter_fast",
				title => "16:9 Anam. Enc., Letterbox, Fast Resize",
				tc_clip1_top	=> 64,
				tc_clip1_bottom	=> 64,
				tc_clip1_left	=> 40,
				tc_clip1_right	=> 40,
				tc_zoom_width	=> 640,
				tc_zoom_height	=> 320,
				tc_clip2_top	=> 4,
				tc_clip2_bottom	=> 4,
				tc_clip2_left	=> 0,
				tc_clip2_right	=> 0,
				tc_fast_resize  => 1,
			),
		],
	};
	
	return bless $self, $type;
}

sub load {
	my $self = shift;
	
	my $filename = $self->filename;
	confess "no filename set" if not $filename;
	confess "can't read $filename" if not -r $filename;
	
	my $config;
	$config = do $filename;
	confess "can't load $filename. Perl error: $@" if $@;

	my $presets = $self->presets;

	%{$self} = %{$config};
	
	# actually we overide presets, since no user editable
	# presets exist
	$self->set_presets ($presets);
	
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
	print $fh q{# $Id: Config.pm,v 1.6 2002/01/03 17:40:00 joern Exp $},"\n";
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