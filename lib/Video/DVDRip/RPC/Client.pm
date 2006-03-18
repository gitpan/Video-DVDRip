# $Id: Client.pm,v 1.10 2004/04/11 23:36:20 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::RPC::Client;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Video::DVDRip::RPC::Message;

use Carp;
use strict;
use IO::Socket;

sub server			{ shift->{server}			}
sub port			{ shift->{port}				}
sub sock			{ shift->{sock}				}
sub loaded_classes		{ shift->{loaded_classes}		}
sub error_cb			{ shift->{error_cb}			}

sub connected			{ shift->{connected}			}
sub set_connected		{ shift->{connected}		= $_[1]	}

my $self = bless { loaded_classes => {}, connected => 0 }, 'Video::DVDRip::RPC::Client';

sub connect {
	my $class = shift;
	my %par = @_;
	my  ($server, $port, $error_cb) =
	@par{'server','port','error_cb'};
	
	croak "double client connection detected" if $self->connected;
	
	my $sock = IO::Socket::INET->new(
		Proto     => 'tcp',
        	PeerPort  => $port,
        	PeerAddr  => $server,
		Type      => SOCK_STREAM
	) or croak "Can't open connection to $server:$port - $!";

	my $loaded_classes = $self->loaded_classes;

	%{$self} = (
		server	        => $server,
		port  	        => $port,
		sock  	        => $sock,
		error_cb        => $error_cb,
		loaded_classes  => $loaded_classes,
		connected       => 1,
	);

	return bless $self, $class;
}

sub log_connect {
	my $class = shift;
	my %par = @_;
	my ($server, $port) = @par{'server','port'};
	
	my $sock = IO::Socket::INET->new(
		Proto     => 'tcp',
        	PeerPort  => $port,
        	PeerAddr  => $server,
		Type      => SOCK_STREAM
	) or croak "Can't open connection to $server:$port - $!";

	return $sock;
}

sub disconnect {
	my $self = shift;

	my $sock = $self->sock;
	print $sock "DISCONNECT\n";
	close ($sock);

	$self->set_connected(0);

	1;
}

sub DESTROY {
	shift->disconnect;
}

sub error {
	my $self = shift;

	my $error_cb = $self->error_cb;
	
	if ( $error_cb ) {
		my $message = &$error_cb;
		$message ||= "msg: Client/Server communication aborted";
		$self->set_connected(0);
		croak $message;

	} else {
		$self->disconnect;
		croak "Unhandled error in client/server communication";
	}
	
	1;
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

	# create local destructor for this class
	if ( 0 ) {
		no strict 'refs';
		my $local_method = $local_class.'::'."DESTROY";

		# print "Registering local method: $local_method\n";

		*$local_method = sub {
			Carp::cluck();
			my $oid_ref = shift;
			$self->send_request (
				cmd    => "destroy",
				oid    => ${$oid_ref},
			);
			# print "destroy: $local_method ${$oid_ref}\n";
		};
	}

	# create local methods for this class
	foreach my $method ( keys %{$methods} ) {
		$local_method = "$local_class".'::'."$method";

		my $method_type = $methods->{$method};

		# print "Registering local method: $local_method / type=$method_type\n";
		
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
#print "${$oid_ref}: method=$request_method length(answer)=".length(Data::Dumper::Dumper($rc)),"\n";
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
	
	my $request = Video::DVDRip::RPC::Message->pack (\%request);

	my $sock = $self->sock;

	print $sock $request, "\n" or return $self->error;

	my $rc = <$sock>;

	$rc = Video::DVDRip::RPC::Message->unpack ($rc);

	return $self->error if not defined $rc;

	if ( not $rc->{ok} ) {
		$rc->{msg} .= "\n" if not $rc->{msg} =~ /\n$/;
		croak "$rc->{msg}".
		      "Called via Video::DVDRip::RPC::Client";
	}

	return $rc;
}

1;

