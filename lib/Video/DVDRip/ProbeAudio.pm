# $Id: ProbeAudio.pm,v 1.4 2002/11/01 16:12:43 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::ProbeAudio;

use base Video::DVDRip::Base;

use Carp;
use strict;

# Attributes of the audio channel on DVD

sub type			{ shift->{type}				}
sub lang			{ shift->{lang}				}
sub channels			{ shift->{channels}			}
sub bitrate			{ shift->{bitrate}			}
sub sample_rate			{ shift->{sample_rate}			}
sub volume_rescale		{ shift->{volume_rescale}		}
sub scan_output			{ shift->{scan_output}			}

sub set_type			{ shift->{type}			= $_[1]	}
sub set_lang			{ shift->{lang}			= $_[1]	}
sub set_channels		{ shift->{channels}		= $_[1]	}
sub set_bitrate			{ shift->{bitrate}		= $_[1]	}
sub set_sample_rate		{ shift->{sample_rate}		= $_[1]	}
sub set_volume_rescale		{ shift->{volume_rescale}	= $_[1]	}
sub set_scan_output		{ shift->{scan_output}		= $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my  ($type, $lang, $channels, $bitrate, $volume_rescale) =
	@par{'type','lang','channels','bitrate','volume_rescale'};
	my  ($sample_rate, $scan_output) =
	@par{'sample_rate','scan_output'};

	my $self = {
		type			=> $type,
		lang			=> $lang,
		channels		=> $channels,
		bitrate			=> $bitrate,
		sample_rate		=> $sample_rate,
		volume_rescale		=> $volume_rescale,
		scan_output		=> $scan_output,
	};
	
	return bless $self, $class;
}

sub ac3_ok {
	my $self = shift;

	my $ok = ($self->type eq 'ac3' and $self->bitrate ne '');

	return $ok;
}

sub pcm_ok {
	my $self = shift;

	my $ok = ($self->type eq 'lpcm' and $self->bitrate ne '');

	return $ok;
}

1;
