# $Id: Server.pm,v 1.16 2005/12/26 13:57:47 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::RPC::Server;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use base Video::DVDRip::Base;

use Video::DVDRip::RPC::Message;

use Carp;
use strict;
use Symbol;
use Socket;

use Event;
use constant NICE => -1;

$Event::DIED = sub {
	Event::verbose_exception_handler(@_);
	Event::unloop_all();
};

sub port			{ shift->{port}				}
sub set_port			{ shift->{port}			= $_[1] }

sub name			{ shift->{name}				}
sub set_name			{ shift->{name}			= $_[1] }

sub classes			{ shift->{classes}			}
sub set_classes			{ shift->{classes}		= $_[1] }

sub loaded_classes		{ shift->{loaded_classes}		}
sub set_loaded_classes		{ shift->{loaded_classes}	= $_[1] }

sub clients_connected		{ shift->{clients_connected}		}
sub set_clients_connected	{ shift->{clients_connected}	= $_[1] }

sub log_clients_connected	{ shift->{log_clients_connected}	}
sub set_log_clients_connected	{ shift->{log_clients_connected}= $_[1] }

sub logging_clients		{ shift->{logging_clients}		}
sub set_logging_clients		{ shift->{logging_clients}	= $_[1] }

sub log_level			{ shift->{log_level}			}
sub set_log_level		{ shift->{log_level} 		= $_[1]	}

my $INSTANCE;
sub instance { $INSTANCE }

sub new {
	my $class = shift;
	my %par = @_;
	my  ($port, $classes, $name) =
	@par{'port','classes','name'};
	
	my $self = bless {}, $class;

	$self->set_port ($port);
	$self->set_name ($name);
	$self->set_classes ($classes);
	$self->set_loaded_classes ({});
	$self->set_logging_clients ({});
	$self->set_clients_connected (0);
	
	$INSTANCE = $self;

	$self->set_logger ($self);

	return $self;
}

sub start {
	my $self = shift;

	$self->log (__x("{name} started", name => $self->name));

	# setup rpc listener
	my $proto = getprotobyname('tcp');
	my $sock  = gensym();
	my $port  = $self->port;
	
	socket($sock, PF_INET, SOCK_STREAM, $proto)
		or die "socket: $!";
	setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack('l', 1))
        	or die "setsockopt: $!";
	bind($sock, sockaddr_in($port, INADDR_ANY))
		or die "bind: $!";
	listen($sock, SOMAXCONN);

	Event->io (
		fd   => $sock,
		poll => 'r',
		nice => NICE,
		cb   => [ $self, "accept_new_client" ],
		desc => "rpc listener port $port"
	);

	$self->log (__x("Started rpc listener on TCP port {port}",
			port => $self->port));

	# setup log listener
	$proto = getprotobyname('tcp');
	$sock  = gensym();
	$port  = $self->port + 10;

	socket($sock, PF_INET, SOCK_STREAM, $proto)
		or die "socket: $!";
	setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack('l', 1))
        	or die "setsockopt: $!";
	bind($sock, sockaddr_in($port, INADDR_ANY))
		or die "bind: $!";
	listen($sock, SOMAXCONN);

	Event->io (
		fd   => $sock,
		poll => 'r',
		nice => NICE,
		cb   => [ $self, "accept_new_log_client" ],
		desc => "log listener port $port"
	);

	$self->log (__x("Started log listener on TCP port {port}",
		    port => $port));

	Event::loop();

	$self->log (__"Server stopped");

	1;
}

sub accept_new_client {
	my $self = shift;
	my ($event) = @_;
	
	my $sock = gensym;
	my $paddr = accept $sock, $event->w->fd or die "accept: $!";
	my ($port, $ip) = sockaddr_in($paddr);

	$ip = inet_ntoa($ip);

	# switch off buffering
	my $old_fd = select $sock;
	$| = 1;
	select $old_fd;

	Video::DVDRip::RPC::Server::Client->new (
		ip     => $ip,
		port   => $port,
		sock   => $sock,
		server => $self,
	);

	$self->set_clients_connected ( 1 + $self->clients_connected );

	1;
}

sub accept_new_log_client {
	my $self = shift;
	my ($event) = @_;
	
	my $sock = gensym;
	my $paddr = accept $sock, $event->w->fd or die "accept: $!";
	my ($port, $ip) = sockaddr_in($paddr);

	$ip = inet_ntoa($ip);

	# switch off buffering
	my $old_fd = select $sock;
	$| = 1;
	select $old_fd;

	my $log_client = Video::DVDRip::RPC::Server::LogClient->new (
		ip     => $ip,
		port   => $port,
		sock   => $sock,
		server => $self,
	);

	$self->set_log_clients_connected ( 1 + $self->log_clients_connected );
	$self->logging_clients->{$log_client->cid} = $log_client;

	1;
}

sub load_class {
	my $self = shift;
	my %par = @_;
	my ($class) = @par{'class'};

	my $client = Video::DVDRip::RPC::Server::Client->new (
		server => $self,
	);
	
	$client->load_class ( class => $class );
	
	$class;
}

sub log {
	my $self = shift;
	
	my ($level, $msg);
	if ( @_ == 2 ) {
		($level, $msg) = @_;
	} else {
		($msg) = @_;
		$level = 1;
	}

	return if $level > $self->log_level;

	# log this to STDERR
	my $line = localtime(time)." $msg\n";
	print STDERR $line;

	# then push this information to our logging clients
	foreach my $log_client ( values %{$self->logging_clients} ) {
		$log_client->print ($line);
	}

	1;
}

package Video::DVDRip::RPC::Server::Client;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

@Video::DVDRip::RPC::Server::Client::ISA = qw ( Video::DVDRip::Base );

use Carp;
use Socket;

use constant NICE => -1;

my $CONNECTION_ID;

sub cid			{ shift->{cid}				}
sub ip			{ shift->{ip}				}
sub port		{ shift->{port}				}
sub sock		{ shift->{sock}				}
sub server		{ shift->{server}			}
sub watcher		{ shift->{watcher}			}

sub classes		{ shift->{server}->classes		}
sub loaded_classes	{ shift->{server}->loaded_classes	}
sub objects		{ shift->{objects}			}

sub set_watcher		{ shift->{watcher}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($ip, $port, $sock, $server) =
	@par{'ip','port','sock','server'};

	my $cid = ++$CONNECTION_ID;
	
	my $self = bless {
		cid     => $cid,
		ip      => $ip,
		port    => $port,
		sock    => $sock,
		server  => $server,
		objects => {},
		watcher => undef,
	}, $class;

	if ( $sock ) {

		$self->log (2,
			__x("Got connection from {ip}:{port}. Connection ID is {cid}",
			    ip => $ip, port => $port, cid => $cid)
		);
	
		$self->{watcher} = Event->io (
			fd   => $sock,
			poll => 'r',
			nice => NICE,
			cb   => [ $self, "input" ],
			desc => "rpc client cid=$cid",
		);
	}
	
	return $self;
}

sub disconnect {
	my $self = shift;

	close $self->sock;
	$self->watcher->cancel;
	$self->set_watcher(undef);

	$self->server->set_clients_connected ( $self->server->clients_connected - 1 );

	$self->log(2, __"Client disconnected");

	1;
}

sub log {
	my $self = shift;

	my ($level, $msg);
	if ( @_ == 2 ) {
		($level, $msg) = @_;
	} else {
		($msg) = @_;
		$level = 1;
	}

	$msg = "cid=".$self->cid.": $msg";
	
	return $self->server->log ($level, $msg);
}

sub input {
	my $self = shift;

	my $sock = $self->sock;
	return $self->disconnect if eof($sock);

	my $request = <$sock>;	
	
	return $self->disconnect if $request eq "DISCONNECT\n";

	$self->log (4, "Length of input request = ".length($request));

	$request = Video::DVDRip::RPC::Message->unpack ($request);

	my $rc;
	my $cmd = $request->{cmd};

	if ( $cmd eq 'new' ) {
		$rc = $self->create_new_object (
			request => $request,
		);

	} elsif ( $cmd eq 'exec' ) {
		$rc = $self->execute_object_method (
			request => $request,
		);

	} elsif ( $cmd eq 'class_info' ) {
		$rc = $self->get_class_info (
			request => $request,
		);

	} elsif ( $cmd eq 'destroy' ) {
		$rc = $self->destroy_object (
			request => $request,
		);

	} else {
		$self->log ("Unknown request command '$cmd'");
		$rc = {
			ok  => 0,
			msg => "Unknown request command '$cmd'",
		};
	}

	$rc = Video::DVDRip::RPC::Message->pack ($rc);

	$self->log (4, "Length of request answer = ".length($rc));

	print $sock $rc,"\n";

	1;
}

sub create_new_object {
	my $self = shift;
	my %par = @_;
	my ($request) = @par{'request'};

	# Let's create a new object
	my $class_method = $request->{method};
	my $class = $class_method;
	$class =~ s/::[^:]+$//;
	$class_method =~ s/^.*:://;

	# check if access to this class/method is allowed
	if ( not defined $self->classes->{$class}->{$class_method} or
	     $self->classes->{$class}->{$class_method} ne '_constructor' ) {
		$self->log ("Illegal constructor access to $class->$class_method");
		return {
			ok  => 0,
			msg => "Illegal constructor access to $class->$class_method"
		};

	}
	
	# load the class if not done yet
	$self->load_class ( class => $class );

	# resolve object params
	$self->resolve_object_params ( params => $request->{params} );

	# ok, the class is there, let's execute the method
	my $object = eval {
		$class->$class_method (@{$request->{params}})
	};

	# report error
	if ( $@ ) {
		$self->log ("Error: can't create object ".
			    "($class->$class_method): $@");
		return {
			ok  => 0,
			msg => $@,
		};
	}

	# store object
	my $oid = "$object";

	$self->objects->{$oid} = {
		object => $object,
		class  => $class
	};

	# log and return
	$self->log (3,
		__x("Created new object {object} with oid {oid}",
		    object => "$class->$class_method",
		    oid    => $oid)
	);

	return {
		ok  => 1,
		oid => $oid,
	};
}

sub load_class {
	my $self = shift;
	my %par = @_;
	my ($class) = @par{'class'};
	
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
	
		$self->log (4, "Class '$class' ($load_class_info->{filename}) changed on disk. Reloading...")
			if $mtime > $load_class_info->{mtime};

		do $load_class_info->{filename};

		if ( $@ ) {
			$self->log (__x("Can't load class '{class}': {error}", class => $class, error => $@));
			$load_class_info->{mtime} = 0;

			return {
				ok  => 0,
				msg => "Can't load class $class: $@",
			};

		} else {
			$self->log (3, __x("Class {class}' successfully loaded", class => $class));
			$load_class_info->{mtime} = time;
		}
	}
	
	$self->log (4, "filename=".$load_class_info->{filename}.
		    ", mtime=".$load_class_info->{mtime} );

	$self->loaded_classes->{$class} ||= $load_class_info;

	1;
}

sub execute_object_method {
	my $self = shift;
	my %par = @_;
	my ($request) = @par{'request'};

	# Method call of an existent object
	my $oid = $request->{oid};
	my $object_entry = $self->objects->{$oid};
	my $method = $request->{method};

	if ( not defined $object_entry ) {
		# object does not exists
		$self->log ("Illegal access to unknown object with oid=$oid");
		return {
			ok  => 0,
			msg => "Illegal access to unknown object with oid=$oid"
		};

	}
	
	my $class = $object_entry->{class};
	if ( not defined $self->classes->{$class}->{$method} ) {
		# illegal access to this method
		$self->log ("Illegal access to $class->$method");
		return {
			ok  => 0,
			msg => "Illegal access to $class->$method"
		};

	}
	
	# (re)load the class if not done yet
	$self->load_class ( class => $class );

	# resolve object params
	$self->resolve_object_params ( params => $request->{params} );

	# ok, try executing the method
	my @rc = eval {
		$object_entry->{object}->$method (@{$request->{params}})
	};

	# report error
	if ( $@ ) {
		$self->log ("Error: can't call '$method' of object ".
			    "with oid=$oid: $@");
		return {
			ok  => 0,
			msg => $@,
		};
	}
	
	# log
	$self->log (4, "Called method '$method' of object ".
		       "with oid=$oid");

	# check if objects are returned by this method
	# and register them in our internal object table
	# (if not already done yet)
	my $key;
	foreach my $rc ( @rc ) {
		if ( ref ($rc) and ref ($rc) !~ /ARRAY|HASH|SCALAR/ ) {
			# returns a single object
			$self->log (4, "Method returns object: $rc");
			$key = "$rc";
			if ( not defined $self->objects->{$key} ) {
				$self->objects->{$key}->{object} = $rc;
				$self->objects->{$key}->{class}  = ref $rc;
				$self->log (5, "Object $rc registered ".(ref $rc));
			}
			$rc = $key;

		} elsif ( ref $rc eq 'ARRAY' ) {
			# possibly returns a list of objects
			# make a copy, otherwise the original object references
			# will be overwritten
			my @val = @{$rc};
			$rc = \@val;
			foreach my $val ( @val ) {
				if ( ref ($val) and ref ($val) !~ /ARRAY|HASH|SCALAR/ ) {
					$self->log (4, "Method returns object lref: $val");
					$key = "$val";
					if ( not defined $self->objects->{$key} ) {
						$self->objects->{$key}->{object} = $val;
						$self->objects->{$key}->{class}  = ref $val;
						$self->log (5, "Object $val registered ".(ref $val));
					}
					$val = $key;
				}
			}
		} elsif ( ref $rc eq 'HASH' ) {
			# possibly returns a hash of objects
			# make a copy, otherwise the original object references
			# will be overwritten
			my %val = %{$rc};
			$rc = \%val;
			foreach my $val ( values %val ) {
				if ( ref ($val) and ref ($val) !~ /ARRAY|HASH|SCALAR/ ) {
					$self->log (4, "Method returns object href: $val");
					$key = "$val";
					if ( not defined $self->objects->{$key} ) {
						$self->objects->{$key}->{object} = $val;
						$self->objects->{$key}->{class}  = ref $val;
						$self->log (5, "Object $val registered ".(ref $val));
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

sub destroy_object {
	my $self = shift;
	my %par = @_;
	my ($request) = @par{'request'};

	# Destroy existant object
	my $oid = $request->{oid};
	my $object_entry = $self->objects->{$oid};

	if ( not defined $object_entry ) {
		# object does not exists
		$self->log ("Illegal access to unknown object with oid=$oid");
		return {
			ok  => 0,
			msg => "Illegal access to unknown object with oid=$oid"
		};

	}

	# simply delete cache entry: this will implicitely call
	# a destructor, if there is one
	delete $self->objects->{$oid};
	
	print "DESTROY $oid\n";

	return {
		ok => 1
	};
}

sub get_class_info {
	my $self = shift;
	my %par = @_;
	my ($request) = @par{'request'};

	my $class = $request->{class};
	
	if ( not defined $self->classes->{$class} ) {
		$self->log ("Unknown class '$class'");
		return {
			ok  => 0,
			msg => "Unknown class '$class'"
		};
	}
	
	$self->log (4, "Class info for '$class' requested");

	return {
		ok           => 1,
		methods      => $self->classes->{$class},
	};
}

sub resolve_object_params {
	my $self = shift;
	my %par = @_;
	my ($params) = @par{'params'};
	
	my $key;
	foreach my $par ( @{$params} ) {
		if ( defined $self->classes->{ref($par)} ) {
			$key = ${$par};
			$key = "$key";
			croak "unknown object with key '$key'"
				if not defined $self->objects->{$key};
			$par = $self->objects->{$key}->{object};
		}
	}
	
	1;
}


package Video::DVDRip::RPC::Server::LogClient;
use Locale::TextDomain qw (video.dvdrip);
use Video::DVDRip::FixLocaleTextDomainUTF8;

use Carp;
use Socket;

use constant NICE => -1;

my $LOG_CONNECTION_ID;

sub cid			{ shift->{cid}				}
sub ip			{ shift->{ip}				}
sub port		{ shift->{port}				}
sub sock		{ shift->{sock}				}
sub server		{ shift->{server}			}
sub watcher		{ shift->{watcher}			}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($ip, $port, $sock, $server) =
	@par{'ip','port','sock','server'};

	my $cid = ++$LOG_CONNECTION_ID;
	
	my $self = bless {
		cid     => $cid,
		ip      => $ip,
		port    => $port,
		sock    => $sock,
		server  => $server,
		watcher => undef,
	}, $class;

	$self->{watcher} = Event->io (
		fd => $sock,
		poll => 'r',
		nice => NICE,
		cb => [ $self, 'input' ],
		desc => "log reader $cid"
	);

	$self->log (2,
		__x("Got logger connection from {ip}:{port}. Connection ID is {cid}",
		    ip => $ip, port => $port, cid => $cid));
	
	return $self;
}

sub disconnect {
	my $self = shift;

	$self->watcher->cancel;
	close $self->sock;

	$self->server->set_log_clients_connected ( $self->server->log_clients_connected - 1 );
	delete $self->server->logging_clients->{$self->cid};

	$self->log(2, __x("Log client disconnected"));

	1;
}

sub log {
	my $self = shift;

	my ($level, $msg);
	if ( @_ == 2 ) {
		($level, $msg) = @_;
	} else {
		($msg) = @_;
		$level = 1;
	}

	$msg = "lcid=".$self->cid.": $msg";
	
	return $self->server->log ($level, $msg);
}

sub input {
	my $self = shift;

	my $sock = $self->sock;
	$self->disconnect if eof($self->sock);
	<$sock>;
	
	1;
}

sub print {
	my $self = shift;
	my ($msg) = @_;

	my $sock = $self->sock;
	print $sock $msg;
	
	1;
}

1;
