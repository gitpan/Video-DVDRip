# $Id: Server.pm,v 1.1 2002/01/19 11:05:37 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::RPC::Server;

use base Video::DVDRip::Base;

use Carp;
use strict;
use Storable;
use Socket qw(inet_ntoa);

use POE qw( Wheel::SocketFactory  Wheel::ReadWrite
            Filter::Line          Driver::SysRW );

my $CONNECTION_ID;

sub port		{ shift->{port}				}
sub set_port		{ shift->{port}			= $_[1] }

sub oid			{ shift->{oid}				}
sub set_oid		{ shift->{oid}			= $_[1] }

sub classes		{ shift->{classes}			}
sub set_classes		{ shift->{classes}		= $_[1] }

sub loaded_classes	{ shift->{loaded_classes}		}
sub set_loaded_classes	{ shift->{loaded_classes}	= $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my ($port, $classes) = @par{'port','classes'};
	
	my $self = bless {}, $class;

	$self->set_port ($port);
	$self->set_oid (0);
	$self->set_classes ($classes);
	$self->set_loaded_classes ({});

	return $self;
}

sub start_server {
	my $self = shift;

	POE::Session->create (
		object_states => [
			$self => [ '_start', '_stop',
				   'accept_new_client', 'accept_failed' ]
		],
	);

	$poe_kernel->run();
	
	1;
}

sub _start {
	my $self = $_[OBJECT];

	$_[HEAP]->{listener} = POE::Wheel::SocketFactory->new (
		BindPort     => $self->port,
		Reuse        => 'yes',
		SuccessState => "accept_new_client",
		FailureState => "accept_failed",
	);
	
	$self->log ("Master daemon started listening on port ".$self->port);
	
	1;
}

sub _stop {
	my $self = $_[OBJECT];

	$self->log ("Master daemon stopped");
	
	1;
}

sub accept_new_client {
	my $self = $_[OBJECT];
	my ($socket, $peeraddr, $peerport) = @_[ARG0 .. ARG2];

	$peeraddr = inet_ntoa($peeraddr);

	POE::Session->create (
		object_states => [
			$self => {
				_start       => 'client_start',
				_stop	     => 'client_done',
				client_error => 'client_error',
				client_input => 'client_input',
			}
		],
		args => [ $socket, $peeraddr, $peerport ],
	);

	1;
}

sub accept_failed {
	my $self = $_[OBJECT];
	my ($function, $error) = @_[ARG0, ARG2];

	delete $_[HEAP]->{listener};

	$self->log ("Call to $function() failed: $error");
	
	1;
}

sub client_start {
	my $self = $_[OBJECT];
	my ($heap, $socket) = @_[HEAP, ARG0];

	$heap->{readwrite} = POE::Wheel::ReadWrite->new (
		Handle     => $socket,
		Driver     => POE::Driver::SysRW->new(),
		Filter     => POE::Filter::Line->new(),
		InputState => 'client_input',
		ErrorState => 'client_error',
	);
	
	$heap->{peername} = join ':', @_[ARG1, ARG2];
	$heap->{id} = "cid=".++$CONNECTION_ID;

	$self->log (2, "Got connection from $heap->{peername}. Connection ID is $heap->{id}");

	1;
}

sub client_done {
	my $self = $_[OBJECT];
	my $heap = $_[HEAP];

	delete $_[HEAP]->{readwrite};

	$self->log(2, "Client $heap->{id} disconnected from ".$_[HEAP]->{peername});
	
	1;
}

sub client_error {
	my $self = $_[OBJECT];
	my $heap = $_[HEAP];

	my ($function, $error) = @_[ARG0, ARG2];

	delete $_[HEAP]->{readwrite};
	
	$self->log ("$heap->{id}: Call to $function() failed: $error") if $error;
	
	1;
}

sub client_input {
	my $self = $_[OBJECT];
	my $request = $_[ARG0];
	my $heap = $_[HEAP];

	# Storable data is compressed into one line. First unpack this.
	$request =~ s/\\n/\n/g;
	$request =~ s/\\\\/\\/g;
	$request = Storable::thaw($request);

	#-------------------------------------------------------------
	# 1. $request = {
	#	cmd	  => 'new',
	#	method    => 'Foo::new',
	#	params	  => [ ... ]
	#    };
	#
	#    => returns object identifier to network client
	#    => stores object reference accessable through
	#	the object identifier in POE Session
	#
	# 2. $request => {
	#	cmd	  => 'exec',
	#	oid	  => Object Identifier returned by 1st step,
	#	method    => 'bra',
	#	params    => [ ... ]
	#    };
	#
	#    => returns return value of method call to network client
	#
	# 3. $request => {
	#	cmd	  => 'class_info'
	#	class	  => name of class whose methods should
	#		     returned
	#    };
	#
	#    => returns list of allowed methods
	#-------------------------------------------------------------

	my $rc;
	my $cmd = $request->{cmd};

	if ( $cmd eq 'new' ) {
		$rc = $self->create_new_object (
			request => $request,
			heap    => $_[HEAP]
		);

	} elsif ( $cmd eq 'exec' ) {
		$rc = $self->execute_object_method (
			request => $request,
			heap    => $_[HEAP]
		);

	} elsif ( $cmd eq 'class_info' ) {
		$rc = $self->get_class_info (
			request => $request,
			heap    => $_[HEAP]
		);

	} else {
		$self->log ("$heap->{id}: Unknown request command '$cmd'");
		$rc = {
			ok  => 0,
			msg => "Unknown request command '$cmd'",
		};
	}

	$rc = Storable::freeze ( $rc );
	$rc =~ s/\\/\\\\/g;
	$rc =~ s/\n/\\n/g;
	
	$_[HEAP]->{readwrite}->put( $rc );

	1;
}

sub create_new_object {
	my $self = shift;
	my %par = @_;
	my ($request, $heap) = @par{'request','heap'};

	# Let's create a new object
	my $class_method = $request->{method};
	my $class = $class_method;
	$class =~ s/::[^:]+$//;
	$class_method =~ s/^[^:]+:://;

	# check if access to this class/method is allowed
	if ( not defined $self->classes->{$class}->{$class_method} or
	     $self->classes->{$class}->{$class_method} ne '_constructor' ) {
		$self->log ("$heap->{id}: Illegal constructor access to $class->$class_method");
		return {
			ok  => 0,
			msg => "Illegal constructor access to $class->$class_method"
		};

	}
	
	# load the class if not done yet
	$self->load_class ( class => $class, heap => $heap );

	# ok, the class is there, let's execute the method
	my $object = eval {
		$class->$class_method (@{$request->{params}})
	};

	# report error
	if ( $@ ) {
		$self->log ("$heap->{id}: Error: can't create object ".
			    "($class->$class_method): $@");
		return {
			ok  => 0,
			msg => $@,
		};
	}

	# store object
	my $oid = $self->set_oid($self->oid+1);

	$heap->{objects}->{$oid} = {
		object => $object,
		class  => $class
	};

	# log and return
	$self->log (3, "$heap->{id}: Created new object ".
		    "($class->$class_method) ".
		    "with oid=$oid");
	return {
		ok  => 1,
		oid => $oid,
	};
}

sub load_class {
	my $self = shift;
	my %par = @_;
	my ($class, $heap) = @par{'class','heap'};
	
	my $mtime;
	my $load_class_info = $self->loaded_classes->{$class};

	if ( not $load_class_info or
	     ( $mtime = (stat($load_class_info->{filename}))[9])
		> $load_class_info->{mtime} ) {
	
		if ( not $load_class_info->{filename} ) {
			my $filename;
			my $rel_filename = $class;
			$rel_filename =~ s!::!/!g;
			$rel_filename .= ".pm";

			foreach my $dir ( @INC ) {
				$filename = "$dir/$rel_filename", last
					if -f "$dir/$rel_filename";
			}

			croak "File for class '$class' not found"
				if not $filename;
			
			$load_class_info->{filename} = $filename;
		}
	
		$self->log (3, "$heap->{id}: Class '$class' ($load_class_info->{filename}) changed on disk. Reloading...")
			if $mtime > $load_class_info->{mtime};

		do $load_class_info->{filename};

		if ( $@ ) {
			$self->log ("$heap->{id}: Can't load class '$class': $@");
			$load_class_info->{mtime} = 0;

			return {
				ok  => 0,
				msg => "Can't load class $class: $@",
			};

		} else {
			$self->log (3, "$heap->{id}: Class '$class' successfully loaded");
			$load_class_info->{mtime} = time;
		}
	}
	
	$self->log (4, "$heap->{id}: filename=".$load_class_info->{filename}.
		    ", mtime=".$load_class_info->{mtime} );

	$self->loaded_classes->{$class} ||= $load_class_info;

	1;
}

sub execute_object_method {
	my $self = shift;
	my %par = @_;
	my ($request, $heap) = @par{'request','heap'};

	# Method call of an existent object
	my $oid = $request->{oid};
	my $object_entry = $heap->{objects}->{$oid};
	my $method = $request->{method};

	if ( not defined $object_entry ) {
		# object does not exists
		$self->log ("$heap->{id}: Illegal access to unknown object with oid=$oid");
		return {
			ok  => 0,
			msg => "Illegal access to unknown object with oid=$oid"
		};

	}
	
	my $class = $object_entry->{class};
	if ( not defined $self->classes->{$class}->{$method} ) {
		# illegal access to this method
		$self->log ("$heap->{id}: Illegal access to $class->$method");
		return {
			ok  => 0,
			msg => "Illegal access to $class->$method"
		};

	}
	
	# (re)load the class if not done yet
	$self->load_class ( class => $class, heap => $heap );

	# ok, try executing the method
	my @rc = eval {
		$object_entry->{object}->$method (@{$request->{params}})
	};

	# report error
	if ( $@ ) {
		$self->log ("$heap->{id}: Error: can't call '$method' of object ".
			    "with oid=$oid: $@");
		return {
			ok  => 0,
			msg => $@,
		};
	}
	
	# log
	$self->log (4, "$heap->{id}: Called method '$method' of object ".
		       "with oid=$oid");

	# check if objects are returned by this method
	# and register them in our internal object table
	# (if not already done yet)
	my $key;
	foreach my $rc ( @rc ) {
		if ( eval { $rc->isa ('UNIVERSAL') } ) {
			# returns a single object
			$self->log (4, "$heap->{id}: Method returns object: $rc");
			$key = "$rc";
			if ( not defined $heap->{objects}->{$key} ) {
				$heap->{objects}->{$key}->{object} = $rc;
				$heap->{objects}->{$key}->{class}  = ref $rc;
			}
			$rc = $key;

		} elsif ( ref $rc eq 'ARRAY' ) {
			# possibly returns a list of objects
			foreach my $val ( @{$rc} ) {
				if ( eval { $val->isa ('UNIVERSAL') } ) {
					$self->log (4, "$heap->{id}: Method returns object lref: $val");
					$key = "$val";
					if ( not defined $heap->{objects}->{$key} ) {
						$heap->{objects}->{$key}->{object} = $val;
						$heap->{objects}->{$key}->{class}  = ref $val;
					}
					$val = $key;
				}
			}
		} elsif ( ref $rc eq 'HASH' ) {
			# possibly returns a hash of objects
			foreach my $val ( values %{$rc} ) {
				if ( eval { $val->isa ('UNIVERSAL') } ) {
					$self->log (4, "$heap->{id}: Method returns object href: $val");
					$key = "$val";
					if ( not defined $heap->{objects}->{$key} ) {
						$heap->{objects}->{$key}->{object} = $val;
						$heap->{objects}->{$key}->{class}  = ref $val;
					}
					$val = $key;
				}
			}
		}
	}

	# return rc
	return {
		ok => 1,
		rc => \@rc,
	};
}

sub get_class_info {
	my $self = shift;
	my %par = @_;
	my ($request, $heap) = @par{'request','heap'};

	my $class = $request->{class};
	
	if ( not defined $self->classes->{$class} ) {
		$self->log ("$heap->{id}: Unknown class '$class'");
		return {
			ok  => 0,
			msg => "Unknown class '$class'"
		};
	}
	
	$self->log (4, "$heap->{id}: Class info for '$class' requested");

	return {
		ok           => 1,
		methods      => $self->classes->{$class},
	};
}

1;
