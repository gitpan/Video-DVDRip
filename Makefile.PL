# $Id: Makefile.PL,v 1.14 2002/06/15 16:27:20 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;

$| = 1;

WriteMakefile(
    'NAME'	=> 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES' => [ 'dvdrip', 'dvdrip-master', 'splitpipe' ],
    'PREREQ_PM' => { 'Gtk' => 0.7008, 'Gtk::Gdk::Pixbuf' => 0 },
    'clean' => { FILES => 'splitpipe src/splitpipe' },
    'dist' => {
         COMPRESS => "gzip",
         SUFFIX   => "gz",
	 PREOP    => 'tools/genreadme > README; tools/add_changes; tools/gensplash',
	 POSTOP   => 'tools/movedist *.tar.gz',
    },
);

sub MY::postamble {
	'
splitpipe: src/Makefile
	cd src && make
';
}
