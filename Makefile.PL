# $Id: Makefile.PL,v 1.13 2002/05/11 17:34:03 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;

$| = 1;

WriteMakefile(
    'NAME'	=> 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES' => [ 'dvdrip', 'dvdrip-master', 'splitpipe' ],
    'PREREQ_PM' => { 'Gtk' => 0.7008 },
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
