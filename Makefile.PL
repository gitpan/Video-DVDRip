# $Id: Makefile.PL,v 1.12 2002/03/31 08:10:53 joern Exp $

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
	 POSTOP   => "cp *.tar.gz htdocs/dist/; test -d dist || mkdir dist; mv *.tar.gz dist",
    },
);

sub MY::postamble {
	'
splitpipe: src/Makefile
	cd src && make
';
}
