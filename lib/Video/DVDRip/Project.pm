# $Id: Project.pm,v 1.15 2001/11/29 20:38:03 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001 J�rn Reder <joern@zyn.de> All Rights Reserved
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Project;

use base Video::DVDRip::Base;

use Carp;
use strict;

use FileHandle;
use Data::Dumper;

use Video::DVDRip::Content;

sub name			{ shift->{name}				}
sub version			{ shift->{version}			}
sub filename			{ shift->{filename}			}
sub dvd_device			{ shift->{dvd_device}			}
sub mount_point			{ shift->{mount_point}			}
sub vob_dir			{ shift->{vob_dir}  			}
sub avi_dir			{ shift->{avi_dir}  			}
sub snap_dir			{ shift->{snap_dir}  			}
sub content			{ shift->{content}			}
sub last_saved_data		{ shift->{last_saved_data}		}
sub selected_title_nr		{ shift->{selected_title_nr}		}

sub set_name			{ shift->{name}			= $_[1] }
sub set_version			{ shift->{version}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_dvd_device		{ shift->{dvd_device}		= $_[1]	}
sub set_mount_point		{ shift->{mount_point}		= $_[1]	}
sub set_vob_dir			{ shift->{vob_dir}  		= $_[1]	}
sub set_avi_dir			{ shift->{avi_dir}  		= $_[1]	}
sub set_snap_dir		{ shift->{snap_dir}		= $_[1]	}
sub set_content			{ shift->{content}		= $_[1] }
sub set_last_saved_data		{ shift->{last_saved_data}	= $_[1] }
sub set_selected_title_nr	{ shift->{selected_title_nr}	= $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my  ($name, $filename) =
	@par{'name','filename'};
	
	confess "missing name" if not $name;
	
	my $self = {
		name              => $name,
		version           => $Video::DVDRip::VERSION,
		filename          => $filename,
		dvd_device	  => "/dev/dvd",
		mount_point	  => undef,
		vob_dir		  => undef,
		avi_dir		  => undef,
		snap_dir	  => undef,
		content  	  => undef,
		last_saved_data   => undef,
		selected_title_nr => undef,
	};
	
	bless $self, $class;

	my $content = Video::DVDRip::Content->new ( project => $self );

	$self->set_content ($content);

	return $self;
}

sub new_from_file {
	my $class = shift;
	my %par = @_;
	my  ($filename) =
	@par{'filename'};
	
	confess "missing filename" if not $filename;
	
	my $self = bless {
		filename => $filename,
	}, $class;
	
	$self->load;
	
	$self->set_filename ($filename);
	$self->set_version ($Video::DVDRip::VERSION);

	return $self;
}

sub save {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->filename;
	confess "not filename set" if not $filename;
	
	my $data_sref = $self->get_save_data;
	
	my $fh = FileHandle->new;

	open ($fh, "> $filename") or confess "can't write $filename";
	print $fh q{# $Id: Project.pm,v 1.15 2001/11/29 20:38:03 joern Exp $},"\n";
	print $fh "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

	print $fh ${$data_sref};
	close $fh;
	
	$self->set_last_saved_data ($data_sref);

	1;
}

sub get_save_data {
	my $self = shift; $self->trace_in;
	
	my $last_saved_data = $self->last_saved_data;
	$self->set_last_saved_data(undef);

	my $filename = $self->filename;
	$self->set_filename(undef);

	my $dd = Data::Dumper->new ( [$self], ['project'] );
	$dd->Indent(1);
	my $data = $dd->Dump;

	$self->set_last_saved_data($last_saved_data);
	$self->set_filename ($filename);

	return \$data;
}

sub changed {
	my $self = shift; $self->trace_in;

	return 1 if not $self->last_saved_data;

	my $actual_data_sref = $self->get_save_data;
	my $saved_data_sref  = $self->last_saved_data;
	
	my $actual = join ("\n", sort split (/\n/, $$actual_data_sref));
	my $saved  = join ("\n", sort split (/\n/, $$saved_data_sref));
	
	return $actual ne $saved;
}

sub load {
	my $self = shift; $self->trace_in;
	
	my $filename = $self->filename;
	croak "no filename set" if not $filename;
	croak "can't read $filename" if not -r $filename;
	
	my $fh = FileHandle->new;
	open ($fh, $filename) or croak "can't read $filename";
	my $data = join ('', <$fh>);
	close $fh;

	croak "File is no dvd::rip file"
		if $data !~ /This file was generated by Video::DVDRip/;

	my $project;
	$project = eval($data);
	croak "can't load $filename. Perl error: $@" if $@;

	%{$self} = %{$project};

	$self->content->set_project ($self);

	$self->set_last_saved_data ($self->get_save_data);
	
	1;
}

1;
