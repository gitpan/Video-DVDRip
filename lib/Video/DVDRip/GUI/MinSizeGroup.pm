# $Id: MinSizeGroup.pm,v 1.1 2002/04/06 10:26:48 joern Exp $

package Video::DVDRip::GUI::MinSizeGroup;

use strict;
use Carp;

sub size_aloc_arg		{ shift->{size_aloc_arg}		}
sub widgets			{ shift->{widgets}			}

sub maximum			{ shift->{maximum}			}
sub set_maximum			{ shift->{maximum}		= $_[1] }
sub signals_received		{ shift->{signals_received}		}
sub set_signals_received	{ shift->{signals_received}	= $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my ($type) = @par{'type'};
	
	# v - control vertical size, h - control horizontal size
	croak "type must be 'h' or 'v'"
		unless $type eq 'h' or $type eq 'v';

	my $self = {
		widgets 	 => [],
		type    	 => $type,
		maximum		 => 0,
		signals_received => 0,

		# index of the size-alloc callback argument
		# for this type
		size_aloc_arg	 => ($type eq 'h' ? 2 : 3),
	};
	
	return bless $self, $class;
}

sub add {
	my $self = shift;
	my ($widget) = @_;
	
	push @{$self->widgets}, $widget;
	
	# Track size-alloc signals which are sent when
	# the widget is realized the first time.
	my $signal;
	$signal = $widget->signal_connect("size-allocate",
		sub {
			$self->note_size (
				widget => $_[0],
				value  => $_[1]->[$self->size_aloc_arg],
				signal => $signal,
			);
		}
	);

	1;
}

sub note_size {
	my $self = shift;
	my %par = @_;
	my  ($widget, $value, $signal) =
	@par{'widget','value','signal'};
	
	# track maximum value
	$self->set_maximum($value) if $value > $self->maximum;

	# count signals received
	$self->set_signals_received ( 1 + $self->signals_received );

	# remove the signal. We are interested only in the first
	# size allocation when the widget is realized. Also this
	# prevents an endless recursion.
	$widget->signal_disconnect ($signal);

	# If the number of size-alloc signals equals the
	# number of widgets all widgets of this group
	# are realized. Now set the usize to the max value
	# of all widgets.
	if ( $self->signals_received == @{$self->widgets} ) {
		foreach my $w ( @{$self->widgets} ) {
			$w->{_mszg_usize} ||= [undef,undef];
			$w->{_mszg_usize}->[$self->size_aloc_arg-2] = $self->maximum;
			$w->set_usize(@{$w->{_mszg_usize}});
		}
	}
	
	1;
}

1;
