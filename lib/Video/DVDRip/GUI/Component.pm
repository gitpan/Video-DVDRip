# $Id: Component.pm,v 1.3 2002/01/03 17:40:01 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Component;

use base Video::DVDRip::GUI::Base;

use strict;

sub widget			{ shift->{widget}		}
sub gtk_win			{ shift->{gtk_win}		}

sub set_widget			{ shift->{widget}	= $_[1] }
sub set_gtk_win			{ shift->{gtk_win}	= $_[1] }

# constructor of components takes additional 'gtk_win' argument

sub new {
	my $class = shift;
	my %par = @_;
	my ($gtk_win) = @par{'gtk_win'};
	
	my $self = {
		gtk_win => $gtk_win
	};
	
	return bless $self, $class;
}

1;
