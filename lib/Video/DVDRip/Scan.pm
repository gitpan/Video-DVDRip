# $Id: Scan.pm,v 1.6 2002/01/03 17:40:00 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Scan;

use base Video::DVDRip::Base;

use Carp;
use strict;

sub scan_output		{ shift->{scan_output}		}
sub volume_rescale	{ shift->{volume_rescale}	}

sub set_scan_output	{ shift->{scan_output}	= $_[1] }
sub set_volume_rescale	{ shift->{volume_rescale}=$_[1] }

sub analyze {
	my $class = shift;
	my %par = @_;
	my  ($scan_output) =
	@par{'scan_output'};

	my ($volume_rescale);

	($volume_rescale) = $scan_output =~ /rescale=([\d.]+)/;

	my $self = {
		scan_output	=> $scan_output,
		volume_rescale	=> $volume_rescale,
	};
	
	return bless $self, $class;
}

1;
