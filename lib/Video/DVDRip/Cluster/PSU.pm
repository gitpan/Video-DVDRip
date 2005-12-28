# $Id: PSU.pm,v 1.5 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::PSU;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::PSU;

use Carp;
use strict;

sub selected			{ shift->{selected}			}
sub set_selected		{ shift->{selected}		= $_[1] }

sub chunk_cnt			{ shift->{chunk_cnt}			}
sub set_chunk_cnt		{ shift->{chunk_cnt}		= $_[1] }

sub state			{ shift->{state}			}
sub set_state			{ shift->{state}		= $_[1] }

1;
