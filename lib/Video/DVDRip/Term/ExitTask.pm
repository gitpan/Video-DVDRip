# $Id: ExitTask.pm,v 1.2 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Term::ExitTask;

use base qw( Video::DVDRip::Task );

use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use Carp;
use strict;

sub configure 	{ 1 }
sub start 	{ shift->ui->glib_main_loop->quit }

1;
