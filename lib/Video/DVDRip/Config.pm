# $Id: Config.pm,v 1.55 2006/01/03 19:36:52 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Config;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

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

sub set_order			{ shift->{order}		= $_[1] }
sub set_presets			{ shift->{presets}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_last_saved_data		{ shift->{last_saved_data}	= $_[1] }

my @BPP = '<none>';
for ( my $b = 1.0; $b > 0 && push @BPP, sprintf("%.2f",$b); $b -= 0.05 ) {};

my @LANG = (
    "en - English", "de - Deutsch", "fr - Francais", "es - Espanol",
    "it - Italiano", "nl - Nederlands",
    "aa - Afar", "ab - Abkhazian", "af - Afrikaans", "am - Amharic",
    "ar - Arabic", "as - Assamese", "ay - Aymara", "az - Azerbaijani",
    "ba - Bashkir", "be - Byelorussian", "bg - Bulgarian", "bh - Bihari",
    "bi - Bislama", "bn - Bengali / Bangla", "bo - Tibetan",
    "br - Breton", "ca - Catalan", "co - Corsican", "cs - Czech", "cy - Welsh",
    "da - Dansk", "dz - Bhutani", "el - Greek",
    "eo - Esperanto", "et - Estonian",
    "eu - Basque", "fa - Persian", "fi - Suomi", "fj - Fiji", "fo - Faroese",
    "fy - Frisian", "ga - Gaelic", "gd - Scots Gaelic",
    "gl - Galician", "gn - Guarani", "gu - Gujarati",
    "ha - Hausa", "he - Hebrew", "hi - Hindi", "hr - Hrvatski", "hu - Magyar",
    "hy - Armenian", "ia - Interlingua", "id - Indonesian",
    "ie - Interlingue", "ik - Inupiak", "in - Indonesian", "is - Islenska",
    "iu - Inuktitut", "iw - Hebrew", "ja - Japanese", 
    "ji - Yiddish", "jw - Javanese", "ka - Georgian", "kk - Kazakh",
    "kl - Greenlandic", "km - Cambodian", "kn - Kannada", "ko - Korean",
    "ks - Kashmiri", "ku - Kurdish", "ky - Kirghiz", "la - Latin",
    "ln - Lingala", "lo - Laothian", "lt - Lithuanian", "lv - Latvian, Lettish",
    "mg - Malagasy", "mi - Maori", "mk - Macedonian", "ml - Malayalam",
    "mn - Mongolian", "mo - Moldavian", "mr - Marathi", "ms - Malay",
    "mt - Maltese", "my - Burmese", "na - Nauru", "ne - Nepali", 
    "no - Norsk", "oc - Occitan", "om - Oromo", "or - Oriya", "pa - Punjabi",
    "pl - Polish", "ps - Pashto, Pushto", "pt - Portugues", "qu - Quechua",
    "rm - Rhaeto-Romance", "rn - Kirundi", "ro - Romanian", "ru - Russian",
    "rw - Kinyarwanda", "sa - Sanskrit", "sd - Sindhi", "sg - Sangho",
    "sh - Serbo-Croatian", "si - Sinhalese", "sk - Slovak", "sl - Slovenian",
    "sm - Samoan", "sn - Shona", "so - Somali", "sq - Albanian", "sr - Serbian",
    "ss - Siswati", "st - Sesotho", "su - Sundanese", "sv - Svenska",
    "sw - Swahili", "ta - Tamil", "te - Telugu", "tg - Tajik", "th - Thai",
    "ti - Tigrinya", "tk - Turkmen", "tl - Tagalog", "tn - Setswana",
    "to - Tonga", "tr - Turkish", "ts - Tsonga", "tt - Tatar", "tw - Twi",
    "ug - Uighur", "uk - Ukrainian", "ur - Urdu", "uz - Uzbek", "vi - Vietnamese",
    "vo - Volapuk", "wo - Wolof", "xh - Xhosa", "yi - Yiddish", "yo - Yoruba",
    "za - Zhuang", "zh - Chinese", "zu - Zulu",
);

my   @LANG_POPUP = ( [ "", "<none>" ] );
push @LANG_POPUP, [ $_, $_ ] for @LANG;

my %CONFIG_PARAMETER = (
	program_name => {
		type  => 'string',
		value => "dvd::rip",
	},
	dvd_device => {
		label => __"DVD device",
		type => 'file',
		value => "/dev/dvd",
	},
	dvd_mount_point => {
		label => __"DVD mount point",
		type => 'dir',
		value => "/cdrom",
	},
	writer_device => {
		label => __"Writer device file",
		type => 'file',
		value => "/dev/cdrom",
	},
	eject_command => {
		label => __"Eject Command",
		type  => 'string',
		value => "eject",
		rules => "executable-command",
	},
	play_dvd_command => {
		label => __"DVD player command",
		type  => 'string',
		value => 'mplayer <dvd://%t -aid %(%a+%b) -chapter %c -dvdangle %m -dvd-device %d>',
		presets => [
			'mplayer <dvd://%t -aid %(%a+%b) -chapter %c -dvdangle %m -dvd-device %d>',
			'xine -a %a -p <dvd://%d/%t.%c>',
		],
		rules => "executable-command",
	},
	play_file_command => {
		label => __"File player command",
		type  => 'string',
		value => 'mplayer <%f>',
		presets => [
			'xine -p <%f>',
			'mplayer <%f>',
		],
		rules => "executable-command",
	},
	play_stdin_command => {
		label => __"STDIN player command",
		type  => 'string',
		value => 'xine stdin://mpeg2 -g -pq -a %a',
		presets => [
			'mplayer -aid %(%a+128) -',
			'xine stdin://mpeg2 -g -pq -a %a',
		],
		rules => "executable-command",
	},
	rar_command => {
		label => __"rar command (for vobsub compression)",
		type  => 'string',
		value => 'rar',
		presets => [
			'rar',
		],
		rules => "executable-command",
	},
	base_project_dir => {
		label => __"Default data base directory",
		type => 'dir',
		value => "/CHANGE_ME",
	},
	dvdrip_files_dir => {
		label => __"Default directory for .rip project files",
		type => 'dir',
		value => "/CHANGE_ME",
		rules => "dir-writable",
	},
	ogg_file_ext => {
		label => __"OGG file extension",
		type  => 'string',
		value => 'ogm',
		presets => [
			'ogg',
			'ogm',
		],
	},
	cluster_master_local => {
		label => __"Start cluster control daemon locally",
		type  => 'switch',
		value => 1,
	},
	cluster_master_server => {
		label => __"Hostname of server with daemon",
		type  => 'string',
		value => "",
	},
	cluster_master_port => {
		label => __"TCP port number of daemon",
		type  => 'number',
		value => 28646,
		rules => "positive-integer",
	},
	default_video_codec => {
		label => __"Default video codec",
		type  => 'string',
		value => 'divx4',
		presets => [
			"SVCD","VCD","XSVCD","XVCD","CVD",
			"divx4","divx5",
			"xvid","xvidcvs","xvid2","xvid3","xvid4",
			"ffmpeg","fame","af6"
		],
	},
	default_container => {
		label => __"Default container format",
		type  => 'popup',
		value => 'avi',
		presets => [ ["avi", "avi" ], [ "ogg", "ogg" ], [ "mpeg", "mpeg" ] ],
	},
	default_bpp => {
		label => __"Default BPP value",
		type  => 'number',
		value => '<none>',
		presets => \@BPP,
		tooltip => __"If this option is set dvd::rip automatically ".
		             "calculates the video bitrate using this BPP value",
		rules => "positive-float",
	},
	burn_cdrecord_device => {
		label => __"cdrecord device (n,n,n or filename)",
		type  => 'string',
		value => '0,X,0',
	},
	burn_writing_speed => {
		label => __"Writing speed",
		type  => 'string',
		value => '16',
		presets => [1,2,4,8,12,16,20,24,30,40],
		rules => "positive-integer",
	},
	burn_test_mode => {
		label => __"Simulate burning",
		type  => 'switch',
		value => 0,
	},
	burn_estimate_size => {
		label => __"Estimate ISO size",
		type  => 'switch',
		value => 0,
		tooltip => __"Estimate the size before start writing. Necessary for some TEAC drives for burning ISO discs on-the-fly",
	},
	burn_cdrecord_cmd => {
		label => __"cdrecord command",
		type  => 'string',
		value => '/usr/lib/xcdroast-0.98/bin/xcdrwrap CDRECORD',
		presets => [
			'/usr/lib/xcdroast-0.98/bin/xcdrwrap CDRECORD',
			'cdrecord',
			'dvdrecord',
		],
		rules => "executable-command",
	},
	burn_mkisofs_cmd => {
		label => __"mkisofs command",
		type  => 'string',
		value => 'mkisofs',
		presets => ['mkisofs'],
		rules => "executable-command",
	},
	burn_vcdimager_cmd => {
		label => __"vcdimager command",
		type  => 'string',
		value => 'vcdimager',
		presets => ['vcdimager'],
		rules => "executable-command",
	},
	burn_cdrdao_cmd => {
		label => __"cdrdao command",
		type  => 'string',
		value => 'cdrdao',
		presets => ['cdrdao'],
		rules => "executable-command",
	},
	burn_cdrdao_driver => {
		label => __"cdrdao driver",
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
		label => __"Overburning",
		type  => 'switch',
		value => 1,
	},
	burn_cdrdao_eject => {
		label => __"Eject disc after write",
		type  => 'switch',
		value => 1,
	},
	burn_cdrdao_buffers => {
		label => __"Buffersize",
		type  => 'string',
		value => '',
		rules => [ "positive-integer", "or-empty" ],
	},
	burn_blank_method => {
		label => __"CD-RW blank method",
		type  => 'popup',
		value => 'fast - minimally blank the entire disk',
		presets => [
			[ 'all - blank the entire disk', 'all - blank the entire disk' ],
			[ 'fast - minimally blank the entire disk',
			  'fast - minimally blank the entire disk' ],
		],
	},

	preferred_lang => {
		label => __"Preferred language",
		type  => 'popup',
		value => '<none>',
		presets => \@LANG_POPUP,
	},
	workaround_nptl_bugs => {
		label	=> __"Workaround transcode NPTL bugs",
		type	=> 'switch',
		value	=> 1,
	},
	nptl_ld_assume_kernel => {
		label   => __"Set LD_ASSUME_KERNEL to",
		type    => "string",
		value   => "2.4.30",
		chained => 1,
	},
);

my @CONFIG_ORDER = (
	__"Filesystem" => [qw(
		dvd_device         dvd_mount_point
		base_project_dir   dvdrip_files_dir
		ogg_file_ext
	)],
	__"Commands" => [qw(
		play_dvd_command   play_file_command
		play_stdin_command rar_command
	)],
	__"CD burning" => [qw(
		writer_device        burn_cdrecord_device
		burn_cdrecord_cmd    burn_cdrdao_cmd
		burn_mkisofs_cmd     burn_vcdimager_cmd
		burn_writing_speed   burn_estimate_size
		burn_blank_method
	)],
	__"cdrdao options" => [qw(
		burn_cdrdao_driver   burn_cdrdao_overburn
		burn_cdrdao_eject    burn_cdrdao_buffers
	)],
	__"Cluster options" => [qw(
		cluster_master_local cluster_master_server
		cluster_master_port  
	)],
	__"Miscellaneous options" => [qw(
		default_video_codec  default_container
		default_bpp
		preferred_lang       
		workaround_nptl_bugs nptl_ld_assume_kernel
	)],
);

sub config_definition { \%CONFIG_PARAMETER }

sub new {
	my $type = shift;
	my %config_parameter = %CONFIG_PARAMETER;
	my @config_order     = @CONFIG_ORDER;

	my @presets = (
		Video::DVDRip::Preset->new (
			name => "nopreset",
			title => __"- No Modifications -",
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
			title => __"Autoadjust, Big Frame Size, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'big',
		),
		Video::DVDRip::Preset->new (
			name => "auto_medium",
			title => __"Autoadjust, Medium Frame Size, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'medium',
		),
		Video::DVDRip::Preset->new (
			name => "auto_small",
			title => __"Autoadjust, Small Frame Size, HQ Resize",
			tc_fast_resize  => 0,
			auto => 1,
			frame_size => 'small',
		),
		Video::DVDRip::Preset->new (
			name => "auto_big_fast",
			title => __"Autoadjust, Big Frame Size, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'big',
		),
		Video::DVDRip::Preset->new (
			name => "auto_medium_fast",
			title => __"Autoadjust, Medium Frame Size, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'medium',
		),
		Video::DVDRip::Preset->new (
			name => "auto_small_fast",
			title => __"Autoadjust, Small Frame Size, Fast Resize",
			tc_fast_resize  => 1,
			auto => 1,
			frame_size => 'small',
		),
		Video::DVDRip::Preset->new (
			name => "vcd_pal_43",
			title => __"VCD 4:3, PAL",
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
			title => __"VCD 16:9, PAL",
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
			title => __"SVCD 16:9 -> 4:3 letterbox, PAL",
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
			title => __"SVCD anamorph, PAL",
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
			name => "xsvcd_pal",
			title => __"XSVCD anamorph, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 720,
			tc_zoom_height	=> 576,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "cvd_pal",
			title => __"CVD anamorph, PAL",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 352,
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
			title => __"VCD 4:3, NTSC",
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
			title => __"VCD 16:9, NTSC",
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
			title => __"SVCD 16:9 -> 4:3 letterbox, NTSC",
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
			title => __"SVCD anamorph, NTSC",
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
		Video::DVDRip::Preset->new (
			name => "xsvcd_ntsc",
			title => __"XSVCD anamorph, NTSC",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 720,
			tc_zoom_height	=> 480,
			tc_clip2_top	=> 0,
			tc_clip2_bottom	=> 0,
			tc_clip2_left	=> 0,
			tc_clip2_right	=> 0,
			tc_fast_resize  => 1,
			tc_fast_bisection => 0,
		),
		Video::DVDRip::Preset->new (
			name => "cvd_ntsc",
			title => __"CVD anamorph, NTSC",
			tc_clip1_top	=> 0,
			tc_clip1_bottom	=> 0,
			tc_clip1_left	=> 0,
			tc_clip1_right	=> 0,
			tc_zoom_width	=> 352,
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

sub init_nptl_bug_workaround {
	my $self = shift;
	
	if ( $self->get_value("workaround_nptl_bugs") ) {
		$ENV{LD_ASSUME_KERNEL} = $self->get_value('nptl_ld_assume_kernel');
	} else {
		delete $ENV{LD_ASSUME_KERNEL};
	}
	
	1;
}

sub load {
	my $self = shift;
	
	my $filename = $self->filename;
	die "filename not set" if $filename eq '';
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
	
	$self->init_nptl_bug_workaround;
	
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
	die "filename not set" if $filename eq '';

	my $data_sref = $self->get_save_data;
	
	my $fh = FileHandle->new;

	open ($fh, "> $filename") or die "can't write $filename";
	print $fh q{# $Id: Config.pm,v 1.55 2006/01/03 19:36:52 joern Exp $},"\n";
	print $fh "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

	print $fh ${$data_sref};
	close $fh;
	
	$self->set_last_saved_data ($data_sref);

	$self->init_nptl_bug_workaround;

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
	return $config->{$name}->{value} = $value;
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
	return $self->config->{$name}->{value} = $value;
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

sub copy_values_from {
	my $self = shift;
	my ($config) = @_;
	
	foreach my $par ( keys %CONFIG_PARAMETER ) {
		$self->set_value($par, $config->get_value($par));
	}

	1;
}

#---------------------------------------------------------------------
# Test methods
#---------------------------------------------------------------------

sub test_play_dvd_command   	{ _executable (@_) 	}
sub test_play_file_command  	{ _executable (@_) 	}
sub test_play_stdin_command 	{ _executable (@_) 	}
sub test_rar_command 		{ _executable (@_) 	}
sub test_dvd_device		{ _exists (@_)		}
sub test_writer_device		{ _exists (@_)		}
sub test_dvd_mount_point	{ _exists (@_)		}
sub test_base_project_dir	{ _writable (@_)	}
sub test_dvdrip_files_dir	{ _writable (@_)	}
sub test_burn_writing_speed	{ _numeric (@_)		}
sub test_burn_cdrecord_device	{ _cdrecord_device (@_)	}
sub test_burn_cdrecord_cmd   	{ _executable (@_) 	}
sub test_burn_cdrdao_cmd   	{ _executable (@_) 	}
sub test_burn_mkisofs_cmd   	{ _executable (@_) 	}
sub test_burn_vcdimager_cmd   	{ _executable (@_) 	}
sub test_burn_cdrdao_buffers    { _numeric_or_empty(@_) }
sub test_cluster_master_port	{ _numeric (@_)		}
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
		return __x("{file} executable : Ok", file => $file);
	} else {
		return __x("{file} not found : NOT Ok", file => $file) if not -e $file;
		return __x("{file} not executable : NOT Ok", file => $file);
	}
}

sub _writable {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	return "has whitespace : NOT Ok" if $value =~ /\s/;

	if ( not -w $value ) {
		return __x("{file} not found : NOT Ok", file => $value) if not -e $value;
		return __x("{file} not writable : NOT Ok", file => $value);
	} else {
		return __x("{file} writable : Ok", file => $value);
	}
}

sub _numeric {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	if ( $value =~ /^\d+$/ ) {
		return __x("{value} is numeric : Ok", value => $value);
	} else {
		return __x("{value} isn't numeric : NOT Ok", value => $value);
	}
}

sub _numeric_or_empty {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	return __"is empty : Ok" if $value eq '';
	return $self->_numeric ($name);
}

sub _cdrecord_device {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	if ( $value =~ /^\d+,\d+,\d+$/ ) {
		return "$value has format n,n,n : Ok";
	} elsif ( -e $value ) {
		return __x("{value} exists : Ok", value => $value);
	} else {
		return __x("{value} has not format n,n,n and is no file : NOT Ok", value => $value);
	}
}

sub _exists {
	my $self = shift;
	my ($name) = @_;
	
	my $value = $self->get_value ($name);

	if ( -e $value ) {
		return __x("{value} exists : Ok", value => $value);
	} else {
		return __x("{value} doesn't exist : NOT Ok", value => $value);
	}
}

sub _one_of_these {
	my $self = shift;
	my ($name, $lref) = @_;
	
	my $value = $self->get_value ($name);

	foreach my $val ( @{$lref} ) {
		return __x("'{value}' is known : Ok", value => $value) if $val eq $value;
	}

	return __x("'{value}' unknown: NOT Ok", value => $value);	
}


1;
