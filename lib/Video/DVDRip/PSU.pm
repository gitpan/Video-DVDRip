# $Id: PSU.pm,v 1.1 2002/02/11 17:10:31 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::PSU;

use base Video::DVDRip::Base;

use Carp;
use strict;

sub nr				{ shift->{nr}				}
sub frames			{ shift->{frames}			}

sub set_nr			{ shift->{nr}			= $_[1] }
sub set_frames			{ shift->{frames}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($nr, $frames) =
	@par{'nr','frames'};

	my $self = bless {
		nr	 => $nr,
		frames	 => $frames,
	}, $class;
	
	return $self;
}

1;
