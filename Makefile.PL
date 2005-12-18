# $Id: Makefile.PL,v 1.26 2005/10/09 12:30:07 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;
use FileHandle;

$| = 1;

WriteMakefile(
    'NAME'         => 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES'    => [
        'bin/dvdrip',        'bin/dvdrip-master',
        'bin/dvdrip-exec',   'bin/dvdrip-multitee',
        'bin/dvdrip-replex', 'bin/dvdrip-subpng',
        'bin/dvdrip-tet',    'bin/dvdrip-splitpipe',
        'bin/dvdrip-progress'
    ],
    'PREREQ_PM' => {
        'Gtk2'                  => 1.081,
        'Gtk2::Ex::FormFactory' => 0.58,
        'Locale::TextDomain'    => 0,
    },
    'clean' => {
              FILES => 'bin/dvdrip-splitpipe src/dvdrip-splitpipe '
            . 'bin/dvdrip-progress src/dvdrip-progress '
            . 'l10n/.mo.installed'
    },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX   => "gz",
        PREOP => 'echo "DONT USE THIS - USE tools/mkdist.pl INSTEAD"; exit 1',
    },
);

sub MY::postamble {
    '
bin/dvdrip-splitpipe bin/dvdrip-progress: src/Makefile
	cd src && make
';
}
