# $Id: Makefile.PL,v 1.15 2002/09/01 15:57:08 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;

$| = 1;

WriteMakefile(
    'NAME'	=> 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES' => [ 'dvdrip', 'dvdrip-master',
    		     'dr_splitpipe', 'dr_progress' ],
    'PREREQ_PM' => { 'Gtk' => 0.7008, 'Gtk::Gdk::Pixbuf' => 0 },
    'clean' => { FILES => 'dr_splitpipe src/dr_splitpipe  dr_progress src/dr_progress' },
    'dist' => {
         COMPRESS => "gzip",
         SUFFIX   => "gz",
	 PREOP    => 'tools/genreadme > README; tools/add_changes; tools/gensplash',
	 POSTOP   => 'tools/movedist *.tar.gz',
    },
);

sub MY::postamble {
	'
dr_splitpipe dr_progress: src/Makefile
	cd src && make
';
}
