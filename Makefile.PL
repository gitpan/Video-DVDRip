# $Id: Makefile.PL,v 1.22 2004/10/10 13:47:41 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;
use FileHandle;

$| = 1;

WriteMakefile(
    'NAME'	=> 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES' => [ 'dvdrip', 'dvdrip-master', 'dr_exec',
    		     'dr_splitpipe', 'dr_progress' ],
    'PREREQ_PM' => { 'Gtk' => 0.7008, 'Gtk::Gdk::Pixbuf' => 0, 'Locale::TextDomain' => 0 },
    'clean' => { FILES => 'dr_splitpipe src/dr_splitpipe dr_progress src/dr_progress l10n/.mo.installed' },
    'dist' => {
         COMPRESS => "gzip",
         SUFFIX   => "gz",
	 PREOP    => 'echo "DONT USE THIS - USE tools/mkdist.pl INSTEAD"; exit 1',
    },
);

sub MY::postamble {
	'
dr_splitpipe dr_progress: src/Makefile
	cd src && make
';
}
