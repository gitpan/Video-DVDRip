# $Id: PSU.pm,v 1.1 2002/02/11 17:10:31 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
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
