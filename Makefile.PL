# $Id: Makefile.PL,v 1.7 2001/12/01 15:32:06 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;

$| = 1;

WriteMakefile(
    'NAME'	=> 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES' => [ 'dvdrip', 'splitpipe' ],
    'PREREQ_PM' => { 'Gtk' => 0.7008 },
    'clean' => { FILES => 'splitpipe src/splitpipe' },
    'dist' => {
         COMPRESS => "gzip",
         SUFFIX   => "gz",
	 PREOP    => 'perl tools/genreadme > README; perl tools/add_changes',
	 POSTOP   => "cp *.tar.gz htdocs/dist/dvdrip.tar.gz; test -d dist || mkdir dist; mv *.tar.gz dist",
    },
);

sub MY::postamble {
	'
splitpipe: src/Makefile
	cd src && make
';
}
