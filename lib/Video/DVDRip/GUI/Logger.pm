# $Id: Logger.pm,v 1.6 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Logger;
use Locale::TextDomain qw (video.dvdrip);

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

sub nuke {
	my $self = shift;

	my $text = $self->text_widget;
	
	my $length = -s $self->project->logfile;
	
	$text->set_point( 0 );
	$text->forward_delete( $length );

	unlink $self->project->logfile;
	
	$self->log (__"Logfile nuked.");
	
	1;
}

1;
