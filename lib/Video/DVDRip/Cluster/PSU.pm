# $Id: PSU.pm,v 1.3 2003/01/28 20:19:57 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::PSU;

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
