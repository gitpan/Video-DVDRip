# $Id: Message.pm,v 1.2 2002/02/17 14:23:01 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::RPC::Message;

use base Video::DVDRip::Base;

use Carp;
use strict;
use Storable;

sub pack {
	my $class = shift;
	my ($ref) = @_;

	my $packed = Storable::freeze ($ref);

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

