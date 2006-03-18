# $Id: BurnCD.pm,v 1.8 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Job::BurnCD;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Job;

use Carp;
use strict;

sub max_size			{ shift->{max_size}			}
sub set_max_size		{ shift->{max_size}		= $_[1]	}

sub test_mode			{ shift->{test_mode}			}
sub set_test_mode		{ shift->{test_mode}		= $_[1]	}

sub erase_cdrw			{ shift->{erase_cdrw}			}
sub set_erase_cdrw		{ shift->{erase_cdrw}		= $_[1]	}

sub wait_for_start		{ shift->{wait_for_start}		}
sub set_wait_for_start		{ shift->{wait_for_start}	= $_[1]	}

sub fixating			{ shift->{fixating}			}
sub set_fixating		{ shift->{fixating}		= $_[1]	}


sub type {
	return "cd burn";
}

sub info {
	my $self = shift;

	my $test_mode = "";
	$test_mode = "(simulation) " if $self->test_mode;

	my $what = $self->erase_cdrw ? __"Erase CD-RW" : __"Burn CD";

	my $info;
	if ( $self->wait_for_start == -1 ) {
		$info = "$what $test_mode";

	} elsif ( $self->wait_for_start == -2 ) {
		$info = __x("{what} {test_mode}- waiting 10 seconds", what => $what, test_mode => $test_mode);

	} elsif ( $self->wait_for_start ) {
		$info = __x("{what} {test_mode}- starting in {wait} seconds", what => $what, test_mode => $test_mode, wait => $self->wait_for_start);

	} elsif ( $self->fixating ) {
		$info = __x("Fixating CD {test_mode}", test_mode => $test_mode);

	} else {
		$info = "$what $test_mode";
	}

	return $info;
}

sub init {
	my $self = shift;
	
	my $title = $self->title;
	
	$self->set_wait_for_start( -1 );

	$self->set_progress_show_fps ( 0 );
	$self->set_progress_show_elapsed ( 0 );
	$self->set_progress_max ( 10000 );

	1;
}

sub command {
	my $self = shift;

	if ( $self->erase_cdrw ) {
		return $self->title->get_erase_cdrw_command;
	} else {
		return $self->title->get_burn_command;
	}
}

sub parse_output {
	my $self = shift;
	my ($line) = @_;

#$line =~ s/[\r\n]//g;
#print "line='$line'\n";

	if ( $line =~ m!(\d+)\s+seconds.! ) {
		if ( $self->title->burn_cd_type ne 'iso' ) {
#print "DAO WARTE 10 SEKUNDEN\n";
			$self->set_wait_for_start (-2);
		} else {
#print "CDR WARTE $1 SEKUNDEN\n";
			$self->set_wait_for_start ( $1 );
		}
		if ( $1 == 0 ) {
			$self->set_progress_show_percent ( 1 );
			$self->set_progress_show_elapsed ( 1 );
		}
	}

	if ( ( $self->title->burning_an_image or 
	       ( ( not $self->title->burning_an_image ) and $self->title->config('burn_estimate_size') ) ) and
	     $line =~ m!(\d+)\s+of\s+(\d+)\s+MB!i ) {
#print "ABBILD: FORTSCHRITT: $1 of $2\n";
		$self->set_progress_cnt ( int(10000*$1/$2) );
		$self->set_fixating(1) if $1 >= $2;
#print "ABBILD: fixiere" if $1 >= $2;
		$self->set_wait_for_start ( 0 );

	} elsif ( ( not $self->title->burning_an_image ) and ( not $self->title->config('burn_estimate_size') ) and 
	          $line =~ m!:\s+(\d+)\s+MB! ) {
		$self->set_progress_cnt ( int(10000*$1/$self->max_size) );
#print "FLY: FORTSCHRITT: $1 of ".$self->max_size,"\n";
		$self->set_fixating(1) if $1 >= $self->max_size;
#print "FLY: fixiere" if $1 >= $self->max_size;
		$self->set_wait_for_start ( 0 );
	}

	$self->set_operation_successful ( 1 )
		if $line =~ /DVDRIP_SUCCESS/;

	1;	
}

1;
