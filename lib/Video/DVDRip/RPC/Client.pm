# $Id: Client.pm,v 1.1 2002/01/19 11:05:37 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::RPC::Client;

use Carp;
use strict;
use Storable;
use IO::Socket;

sub server			{ shift->{server}		}
sub port			{ shift->{port}			}
sub sock			{ shift->{sock}			}
sub loaded_classes		{ shift->{loaded_classes}	}

sub connect {
	my $class = shift;
	my %par = @_;
	my ($server, $port) = @par{'server','port'};
	
	my $sock = IO::Socket::INET->new(
		Proto     => 'tcp',
        	PeerPort  => $port,
        	PeerAddr  => $server,
		Type      => SOCK_STREAM
	) or croak "Can't open connection to $server:$port - $!";

	my $self = {
		server	       => $server,
		port  	       => $port,
		sock  	       => $sock,
		loaded_classes => {},
	};

	return bless $self, $class;
}

sub disconnect {
	my $self = shift;

	my $sock = $self->sock;
	
	close ($sock);
	
	1;
}

sub DESTROY {
	shift->disconnect;
}

sub load_class {
	my $self = shift;
	my %par = @_;
	my ($class) = @par{'class'};

	return 1 if $self->loaded_classes->{$class};

	$self->loaded_classes->{$class} = 1;

	my $rc = $self->send_request (
		cmd   => 'class_info',
		class => $class,
	);
	
	my $local_method;
	my $local_class = $class;
	my $methods = $rc->{methods};

	# create local methods for this class
	foreach my $method ( keys %{$methods} ) {
		$local_method = "$local_class".'::'."$method";
		
		my $method_type = $methods->{$method};
		if ( $method_type eq '_constructor' ) {
			# this is a constructor for this class
			my $request_method = $class.'::'.$method;
			no strict 'refs';
			*$local_method = sub {
				shift;
				my $rc = $self->send_request (
					cmd    => 'new',
					method => $request_method,
					params => \@_,
				);
				my $oid = $rc->{oid};
				return bless \$oid, $local_class;
			};

		} elsif ( $method_type == 1 ){
			# this is a simple method
			my $request_method = $method;
			no strict 'refs';
			*$local_method = sub {
				my $oid_ref = shift;
				my $rc = $self->send_request (
					cmd    => 'exec',
					oid    => ${$oid_ref},
					method => $request_method,
					params => \@_,
				)->{rc};
				return @{$rc} if wantarray;
				return $rc->[0];
			};

		} else {
			# this is a object returner
			my $request_method = $method;
			no strict 'refs';
			*$local_method = sub {
				my $oid_ref = shift;
				my $rc = $self->send_request (
					cmd    => 'exec',
					oid    => ${$oid_ref},
					method => $request_method,
					params => \@_,
				)->{rc};
				foreach my $val ( @{$rc} ) {
					if ( ref $val eq 'ARRAY' ) {
						foreach my $list_elem ( @{$val} ) {
							my $list_elem_copy = $list_elem;
							$list_elem = \$list_elem_copy;
							bless $list_elem, $method_type;
						}
					} elsif ( ref $val eq 'HASH' ) {
						foreach my $hash_elem ( values %{$val} ) {
							my $hash_elem_copy = $hash_elem;
							$hash_elem = \$hash_elem_copy;
							bless $hash_elem, $method_type;
						}
					} else {
						my $val_copy = $val;
						$val = \$val_copy;
						bless $val, $method_type;
					}
				}
				return @{$rc} if wantarray;
				return $rc->[0];
			};
			
			# load this class
			$self->load_class ( class => $method_type );
		}
	}
	
	return $local_class;
}

sub send_request {
	my $self = shift;
	my %request = @_;
	
	my $request = Storable::freeze (\%request);
	$request =~ s/\\/\\\\/g;
	$request =~ s/\n/\\n/g;
	
	my $sock = $self->sock;

	print $sock $request, "\n";
	
	my $rc = <$sock>;
	
	$rc =~ s/\\n/\n/g;
	$rc =~ s/\\\\/\\/g;
	$rc = Storable::thaw($rc);
	
	if ( not $rc->{ok} ) {
		$rc->{msg} .= "\n" if not $rc->{msg} =~ /\n$/;
		croak "$rc->{msg}".
		      "Called via Video::DVDRip::RPC::Client";
	}

	return $rc;
}
	
1;

