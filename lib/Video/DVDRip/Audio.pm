# $Id: Audio.pm,v 1.2 2002/09/22 09:35:09 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 J�rn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Audio;

use base Video::DVDRip::Base;

use Carp;
use strict;

# Options for transcoding the audio channel
sub tc_nr			{ shift->{tc_nr}			}
sub tc_target_track		{ shift->{tc_target_track}		}
sub tc_audio_codec		{ shift->{tc_audio_codec}		}
sub tc_bitrate			{ shift->{tc_bitrate}			}
sub tc_ac3_passthrough		{ shift->{tc_ac3_passthrough}		}
sub tc_mp3_quality		{ shift->{tc_mp3_quality}		}
sub tc_audio_filter		{ shift->{tc_audio_filter}			}
sub tc_option_n			{ shift->{tc_option_n}			}
sub tc_volume_rescale		{ shift->{tc_volume_rescale}		}

sub set_tc_nr			{ shift->{tc_nr}		= $_[1]	}
sub set_tc_target_track		{ shift->{tc_target_track}	= $_[1]	}
sub set_tc_audio_codec		{ shift->{tc_audio_codec}	= $_[1]	}
sub set_tc_bitrate		{ shift->{tc_bitrate}		= $_[1]	}
sub set_tc_ac3_passthrough	{ shift->{tc_ac3_passthrough}	= $_[1]	}
sub set_tc_mp3_quality		{ shift->{tc_mp3_quality}	= $_[1]	}
sub set_tc_audio_filter		{ shift->{tc_audio_filter}	= $_[1]	}
sub set_tc_option_n		{ shift->{tc_option_n}		= $_[1]	}
sub set_tc_volume_rescale	{ shift->{tc_volume_rescale}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($tc_target_track, $tc_audio_codec, $tc_bitrate) =
	@par{'tc_target_track','tc_audio_codec','tc_bitrate'};
	my  ($tc_ac3_passthrough, $tc_mp3_quality, $tc_audio_filter) =
	@par{'tc_ac3_passthrough','tc_mp3_quality','tc_audio_filter'};
	my  ($tc_option_n, $tc_volume_rescale, $tc_nr) =
	@par{'tc_option_n','tc_volume_rescale','tc_nr'};

	$tc_target_track   	  = -1 if not defined $tc_target_track;
	$tc_audio_codec		||= "mp3";
	$tc_bitrate		||= 128;
	$tc_ac3_passthrough	||= 0;
	$tc_mp3_quality		||= 0;
	$tc_audio_filter	||= 'rescale';
	$tc_option_n		||= '';
	$tc_volume_rescale	||= 0;

	my $self = {
		tc_nr			=> $tc_nr,
		tc_target_track		=> $tc_target_track,
		tc_audio_codec		=> $tc_audio_codec,
		tc_bitrate		=> $tc_bitrate,
		tc_ac3_passthrough	=> $tc_ac3_passthrough,
		tc_mp3_quality		=> $tc_mp3_quality,
		tc_audio_filter		=> $tc_audio_filter,
		tc_option_n		=> $tc_option_n,
		tc_volume_rescale	=> $tc_volume_rescale,

    	};
	
	return bless $self, $class;
}

1;
