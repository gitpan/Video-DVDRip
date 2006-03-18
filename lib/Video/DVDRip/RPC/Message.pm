# $Id: Message.pm,v 1.6 2005/06/19 13:41:53 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::RPC::Message;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;
use Storable;

sub pack {
	my $class = shift;
	my ($ref) = @_;

	my $packed = Storable::nfreeze ($ref);

	$packed =~ s/\\/\\\\/g;
	$packed =~ s/\n/\\n/g;
	$packed =~ s/\r/\\r/g;
	
	return $packed;
}

sub unpack {
	my $class = shift;
	my ($packed) = @_;
	
	$packed =~ s/\\r/\r/g;
	$packed =~ s/\\n/\n/g;
	$packed =~ s/\\\\/\\/g;

	return Storable::thaw($packed);
}

1;

