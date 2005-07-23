# $Id: Storage.pm,v 1.2 2005/07/23 11:49:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Storage;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub build_factory {
	my $self = shift;

	return Gtk2::Ex::FormFactory::VBox->new (
	    title 	=> __"Storage",
	    object	=> "project",
	    no_frame    => 1,
	    content 	=> [
	    	Gtk2::Ex::FormFactory::Form->new (
		    title 	=> __"Storage path information",
		    content 	=> [
	    		Gtk2::Ex::FormFactory::Entry->new (
			    name         => "project_name",
			    attr	 => "project.name",
			    label	 => __"Project name",
			    tip		 => __"This is a short name for ".
		    			      "the project. All generated files ".
					      "are named like this.",
			    rules	 => "no-whitespace",
			),
	    		Gtk2::Ex::FormFactory::Entry->new (
			    attr	=> "project.vob_dir",
			    label	=> __"VOB directory",
			    tip		=> __"DVD VOB files are stored here.",
			),
	    		Gtk2::Ex::FormFactory::Entry->new (
			    attr	=> "project.avi_dir",
			    label	=> __"AVI directory",
			    tip		=> __"For transcoded AVI, MPEG and OGM files.",
			),
	    		Gtk2::Ex::FormFactory::Entry->new (
			    attr	=> "project.snap_dir",
			    label	=> __"Temporary directory",
			    tip		=> __"For temporary files",
			),
		    ]
		),
	    	Gtk2::Ex::FormFactory::VBox->new (
		    title 	=> __"Data source mode selection",
		    content 	=> [
	    		Gtk2::Ex::FormFactory::RadioButton->new (
			    attr	 => "project.rip_mode",
			    value	 => "rip",
			    label	 => __"Rip data from DVD to harddisk ".
			    		      "before encoding",
			    tip		 => __"Use this mode if you have enough ".
			    		      "diskspace for a complete copy of ".
					      "the DVD contents. It's the fastest ".
					      "and most flexible DVD mode.",
			),
			Gtk2::Ex::FormFactory::Label->new (
			    label	 => __"Use one of the following modes only, ".
			    		      "if ripping is no option for you.\n".
					      "Many interesting features are disabled ".
					      "for them:\n".
					      "No AC3, no subtitles, no PSU core for ".
					      "NTSC A/V sync optimization and\n".
					      "also preview grabbing and frame range ".
					      "transcoding is rather slow."
			),
	    		Gtk2::Ex::FormFactory::RadioButton->new (
			    attr	 => "project.rip_mode",
			    value	 => "dvd",
			    label	 => __"Encode DVD on the fly",
			    tip		 => __"No DVD contents are copied to harddisk.",
			),
	    		Gtk2::Ex::FormFactory::RadioButton->new (
			    attr	 => "project.rip_mode",
			    value	 => "dvd_image",
			    label	 => __"Use existing DVD image located in ".
			    		      "this directory:",
			    tip		 => __"Use this mode if you have a complete ".
			    		      "image of the DVD on your harddisk already.",
			),
			Gtk2::Ex::FormFactory::Entry->new (
			    attr	 => "project.dvd_image_dir",
			    rules	 => "dir-readable",
			    tip		 => __"This directory must contain a complete ".
			                      "unencrypted copy of the DVD, e.g. it ".
					      "must contain a VIDEO_TS folder",
			),
		    ]
		),
	    ],
	);
}

1;
