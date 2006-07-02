# $Id: Makefile.PL,v 1.33 2006/07/02 14:53:22 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;
use FileHandle;

$| = 1;

WriteMakefile(
    'NAME'         => 'Video::DVDRip',
    'VERSION_FROM' => 'lib/Video/DVDRip.pm',
    'EXE_FILES'    => [
        'bin/dvdrip',          'bin/dvdrip-master',
        'bin/dvdrip-exec',     'bin/dvdrip-multitee',
        'bin/dvdrip-replex',   'bin/dvdrip-subpng',
        'bin/dvdrip-splitpipe',
        'bin/dvdrip-progress', 'bin/dvdrip-splash',
        'bin/dvdrip-thumb'
    ],
    'PREREQ_PM' => {
        'Gtk2'                  => 1.081,
        'Gtk2::Ex::FormFactory' => 0.65,
        'Event::ExecFlow'       => 0.62,
        'Event::RPC'            => 0.89,
        'AnyEvent'              => 1.02,
        'Locale::TextDomain'    => 1.16,
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
