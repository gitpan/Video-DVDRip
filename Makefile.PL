# $Id: Makefile.PL,v 1.11 2002/02/03 16:28:55 joern Exp $

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
	 PREOP    => 'perl tools/genreadme > README; perl tools/add_changes',
	 POSTOP   => "cp *.tar.gz htdocs/dist/; test -d dist || mkdir dist; mv *.tar.gz dist",
    },
);

sub MY::postamble {
	'
splitpipe: src/Makefile
	cd src && make
';
}
