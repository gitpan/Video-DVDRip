# $Id: Logger.pm,v 1.1 2001/12/15 00:21:22 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Logger;

use Carp;
use strict;

sub text_widget			{ shift->{text_widget}			}
sub project			{ shift->{project}			}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($text_widget, $project) =
	@par{'text_widget','project'};
	
	my $self = {
		text_widget => $text_widget,
		project     => $project,
	};
	
	if ( -r $project->logfile ) {
		open (IN, $project->logfile);
		while (<IN>) {
			$text_widget->insert (undef, undef, undef, $_);
		}
		close IN;
	}
	
	return bless $self, $class;
}

sub log {
	my $self = shift;
	
	my $line = localtime(time)." ".$_[0]."\n";

	$self->text_widget->insert (undef, undef, undef, $line);

	open (OUT, ">>".$self->project->logfile);
	print OUT $line;
	close OUT;

	1;
}

1;
