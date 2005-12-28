# $Id: ProbeTitleCount.pm,v 1.4 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::ProbeTitleCount;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Job;

use Carp;
use strict;

sub content			{ shift->{content}			}
sub set_content			{ shift->{content}		= $_[1]	}

sub type {
	return "probe_title_cnt";
}

sub info {
	my $self = shift;

	my $info = __"Determine number of titles";

	return $info;
}

sub init {
	my $self = shift;
	
	$self->set_need_output(1);
	$self->set_progress_show_percent(0);
	1;
}

sub command {
	my $self = shift;

	return $self->content->get_probe_title_cnt_command;
}

sub parse_output {
	my $self = shift;
	my ($buffer) = @_;

	$self->set_operation_successful (1)
		if $buffer =~ /DVDRIP_SUCCESS/;

	1;	
}

sub commit {
	my $self = shift;

	my $content = $self->content;
	my $output  = $self->pipe->output;

	my ($title_cnt) = $output =~ m!DVD\s+title\s+\d+/(\d+)!;

	# Fatal error if we can't determine the title cnt
	if ( not $title_cnt ) {
		croak "Can't determine number of titles.\n".
		      "Please put the DVD in your drive.\n".
		      "tcprobe output was:\n$output";
	}
	
	my ($nr, %titles);
	foreach my $nr ( 1..$title_cnt ) {
		$titles{$nr} = Video::DVDRip::Title->new (
			nr      => $nr,
			project => $content->project,
		);
	}

	# store Title objects
	$content->set_titles (\%titles);

	1;
}

1;
