# $Id: Makefile.PL,v 1.23 2005/07/23 11:38:18 joern Exp $

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
    'PREREQ_PM' => {
        'Gtk2'                  => 1.082,
	'Gtk2::Ex::FormFactory' => 0.56,
	'Locale::TextDomain'    => 0,
    },
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
