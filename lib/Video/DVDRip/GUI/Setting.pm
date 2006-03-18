# $Id: Setting.pm,v 1.2 2004/04/11 23:36:20 joern Exp $

package Video::DVDRip::GUI::Setting;
use Locale::TextDomain qw (video.dvdrip);

use strict;
use Carp;

my %OBJECT_ACCESSORS;
my %SETTINGS_BY_GROUP;
my %SETTINGS_BY_NAME;
my %SETTINGS_BY_OBJECT;

sub add_object_accessor {
	shift;
	Video::DVDRip::GUI::Setting::ObjectAccessor->new ( @_ );
}

sub remove_object_accessor {
	shift;
	my %par = @_;
	Video::DVDRip::GUI::Setting::ObjectAccessor
		->by_name ( $par{name} )->remove;
}

sub update_object_settings {
	shift;
	my %par = @_;
	Video::DVDRip::GUI::Setting::ObjectAccessor
		->by_name ( $par{name} )->update_object_settings;
}

sub add_group {
	shift;
	Video::DVDRip::GUI::Setting::Group->new ( @_ );
}

sub name			{ shift->{name}				}
sub label			{ shift->{label}			}
sub object			{ shift->{object}			}
sub attr			{ shift->{attr}				}
sub widget_hbox			{ shift->{widget_hbox}			}
sub top_widget			{ shift->{top_widget}			}
sub all_widgets			{ shift->{all_widgets}			}
sub groups			{ shift->{groups}			}
sub args			{ shift->{args}				}

sub widget			{ shift->{widget}			}
sub parent_widget		{ shift->{parent_widget}		}

sub set_widget			{ shift->{widget}		= $_[1]	}
sub set_parent_widget		{ shift->{parent_widget}	= $_[1]	}

sub build			{ croak "Implement ->build()"			}
sub get_value			{ croak "Implement ->get_value()"		}
sub changed_signal_name		{ croak "Implement ->changed_signal_name()" 	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($name, $label, $box, $cont, $object, $groups) =
	@par{'name','label','box','cont','object','groups'};
	my  ($table, $row, $row_span, $col, $col_span) =
	@par{'table','row','row_span','col','col_span'};
	my  ($tooltip, $attr, $args) =
	@par{'tooltip','attr','args'};

	if ( $groups and not ref $groups ) {
		$groups = [ $groups ];
	}

	#-----------------------------------------------------------------
	# name		unique name for this setting
	# label		optional label text
	# box		(v|h)box for this widget
	# cont		containter for this widget
	# table		table for this widget
	# row		row of table
	# row_span	row span of this widget (default 1)
	# col		col of table
	# col_span	col span of this widget (default 1)
	# object	underlying object accessor name
	# attr		attribute of the object (->$attr(), set_$attr())
	# group		part of this group (name)
	# args		arguments for a more complex object accessor,
	#		where a simple 'attr' isn't sufficient.
	#-----------------------------------------------------------------

	croak "Specify table, cont or box"
		if (defined $table)+(defined $box)+(defined $cont) != 1;

	croak "Setting '$name' already exists"
		if exists $SETTINGS_BY_NAME{$name};

	my $self = bless {
		name	    		=> $name,  	 
		label	    		=> $label, 	 
		object	    		=> $object,
		groups			=> $groups,
		args			=> $args,
		attr			=> $attr,
		all_widgets		=> {},		# setting specific
	}, $class;

	$self->build ( \%par );

	my $widget        = $self->widget;
	my $parent_widget = $self->parent_widget;

	my $widget_hbox;
	my $top_widget = $parent_widget;

	my $l;
	if ( $label ) {
		$l = Gtk::Label->new ($label);
		$l->set_justify('left');
		$l->show;
	}

	if ( $table ) {
		# add widget to table
		$row_span ||= 1;
		$col_span ||= 1;
		if ( $l ) {
			# optionally with a label
			my $h = Gtk::HBox->new;
			$h->show;
			$h->pack_start ($l, 0, 1, 0);
			$table->attach (
				$h, $col, $col+$col_span, $row, $row+$row_span,
				'fill','expand',0,0
			);
			++$col;
		}
		my $h = Gtk::HBox->new;
		$h->show;
		$h->pack_start ($parent_widget, 0, 1, 0);
		my $v = Gtk::VBox->new;
		$v->show;
		$v->pack_start ($h, 0, 1, 0);
		$table->attach_defaults (
			$v, $col, $col+$col_span, $row, $row+$row_span
		);
		$top_widget = $h;
		$widget_hbox = $h;
	}

	if ( $box ) {
		# add widget to a Box
		if ( $l ) {
			# optionally with a label
			$box->pack_start ( $l, 0, 1, 0);
		}
		$box->pack_start ( $parent_widget, 0, 1, 0 );
		$top_widget = $box;
	}

	if ( $cont ) {
		# add widget to a container
		$cont->add ( $parent_widget );
		$top_widget = $cont;
	}

	$self->{top_widget}  = $top_widget;
	$self->{widget_hbox} = $widget_hbox;

	$self->connect_signals ( @_ ) if $object;

	$widget->signal_connect ("unrealize", sub { $self->remove } );

	if ( $tooltip ) {
		my $tip = Gtk::Tooltips->new;
		$tip->set_tip ($widget, $tooltip, undef);
	}

	# register this setting in several indices

	$SETTINGS_BY_NAME{$name} = $self;

	foreach my $g ( @{$groups} ) {
		$SETTINGS_BY_GROUP{$g}->{$name} = $self;
	}
	
	if ( $object ) {
		$SETTINGS_BY_OBJECT{$object}->{$name} = $self;

	}

	return $self;
}

sub remove {
	my $self = shift;

	my $name = $self->name;
	
	delete $SETTINGS_BY_NAME{$name};

	if ( $self->groups ) {
		foreach my $group ( @{$self->groups} ) {
			delete $SETTINGS_BY_GROUP{$group}->{$name};
		}
	}

	my $object = $self->object;
	delete $SETTINGS_BY_OBJECT{$object}->{$name};
	
	1;
}

sub by_name {
	my $class = shift;
	my ($name) = @_;
	croak "Setting '$name' unknown" if not exists $SETTINGS_BY_NAME{$name};
	return $SETTINGS_BY_NAME{$name};
}

sub connect_signals {
	my $self = shift;
	
	Video::DVDRip::GUI::Setting::ObjectAccessor->connect_changed (
		setting => $self,
		@_
	);

	1;
}

package Video::DVDRip::GUI::Setting::ObjectAccessor;
use Locale::TextDomain qw (video.dvdrip);

sub name			{ shift->{name}				}
sub part_of			{ shift->{part_of}			}
sub access			{ shift->{access}			}
sub set_method			{ shift->{set_method}			}
sub get_method			{ shift->{get_method}			}
sub passed_as			{ shift->{passed_as}			}
sub value_option		{ shift->{value_option}			}

sub update_in_progress		{ shift->{update_in_progress}		}
sub set_update_in_progress	{ shift->{update_in_progress}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($name, $part_of, $access, $set_method, $get_method) =
	@par{'name','part_of','access','set_method','get_method'};
	my  ($passed_as, $value_option) =
	@par{'passed_as','value_option'};

	my $self = {
		name			=> $name,
		part_of			=> $part_of,
		access			=> $access,
		set_method		=> $set_method,
		get_method		=> $get_method,
		passed_as		=> $passed_as,
		value_option		=> $value_option,
	};
	
	# register object accessor
	$OBJECT_ACCESSORS{$name} = $self;

	return bless $self, $class;
}

sub remove {
	my $self = shift;
	
	my $name = $self->name;

	foreach my $setting ( values %{$SETTINGS_BY_OBJECT{$name}} ) {
		$setting->remove;
	}
	
	delete $OBJECT_ACCESSORS{$name};
	
	1;
}

sub by_name {
	my $class = shift;
	my ($name) = @_;
	die "Accessor '$name' unknown" if not exists $OBJECT_ACCESSORS{$name};
	return $OBJECT_ACCESSORS{$name};
}

sub connect_changed {
	my $class = shift;
	my %par = @_;
	my ($setting) = @par{'setting'};

	my $self = Video::DVDRip::GUI::Setting::ObjectAccessor
			->by_name ($setting->object);

	if ( not $self->passed_as ) {
		# simple object accessor
		my $widget = $setting->widget;
		$widget->signal_connect (
			$setting->changed_signal_name,
			sub {
				return 1 if $self->update_in_progress;
				my $set_method = "set_".$setting->attr;
				my $access_cb = $self->access;
				my $object = eval { &$access_cb() };
				return 1 if not $object;
				$object->$set_method($setting->get_value);
				1;
			}
		);

	} elsif ( $self->passed_as eq 'hash' ) {
		# user defined set_method with parameters passed as hash
		my $widget = $setting->widget;
		my $args   = $setting->args;
		$widget->signal_connect (
			$setting->changed_signal_name,
			sub {
				return 1 if $self->update_in_progress;
				my $set_method = $self->set_method;
				my $access_cb = $self->access;
				my $object = eval { &$access_cb() };
				return 1 if not $object;
				$object->$set_method(
					%{$args},
					$self->value_option
						=> $setting->get_value
							(%{$args}),
				);
				1;
			}
		);

	} elsif ( $self->passed_as eq 'array' ) {
		# user defined set_method with parameters as array
		my $widget = $setting->widget;
		my $args   = $setting->args;
		$widget->signal_connect (
			$setting->changed_signal_name,
			sub {
				return 1 if $self->update_in_progress;
				my $set_method = $self->set_method;
				my $access_cb = $self->access;
				my $object = eval { &$access_cb() };
				return 1 if not $object;
				$object->$set_method(
					@{$args},
					$setting->get_value
						( @{$args} ),
				);
				1;
			}
		);

	} else {
		die "No idea what type this accessor is: ".$self->name;
	}

	1;
}

sub get_setting_value {
	my $self = shift;
	my %par = @_;
	my ($setting) = @par{'setting'};
	
	if ( not $self->passed_as ) {
		# simple standard object accessor
		my $get_method = $setting->attr;
		my $access_cb  = $self->access;
		my $object     = eval { &$access_cb() };
		if ( not $object ) {
			$setting->parent_widget->set_sensitive(0);
			return;
		} else {
			$setting->parent_widget->set_sensitive(1);
		}
		return $object->$get_method;
	}
		
	if ( $self->passed_as eq 'hash' ) {
		# user defined set_method with parameters passed as hash
		my $get_method = $self->get_method;
		my $access_cb  = $self->access;
		my $object     = eval { &$access_cb() };
		my $args       = $setting->args;
		if ( not $object ) {
			$setting->parent_widget->set_sensitive(0);
			return;
		} else {
			$setting->parent_widget->set_sensitive(1);
		}
		return $object->$get_method ( %{$args} );
	}
		
	if ( $self->passed_as eq 'array' ) {
		# user defined set_method with parameters passed as array
		my $get_method = $self->get_method;
		my $access_cb  = $self->access;
		my $object     = eval { &$access_cb() };
		my $args       = $setting->args;
		if ( not $object ) {
			$setting->parent_widget->set_sensitive(0);
			return;
		} else {
			$setting->parent_widget->set_sensitive(1);
		}
		return $object->$get_method ( @{$args} );
	}
		

	die "No idea what type this accessor is: ".$self->name;
}

sub update_object_settings {
	my $self = shift;
	
	$self->set_update_in_progress ( 1 );

	foreach my $setting ( values %{$SETTINGS_BY_OBJECT{$self->name}} ) {
		$setting->set_value ( $self->get_setting_value (
			setting => $setting
		) );
	}

	$self->set_update_in_progress ( 0 );
	
	1;
}

package Video::DVDRip::GUI::Setting::Group;
use Locale::TextDomain qw (video.dvdrip);

1;
