# $Id: RedHat-8.0-perl-Video-DVDRip.spec,v 1.1 2002/10/15 21:03:04 joern Exp $

Summary: DVD ripping graphical tool using transcode.
Name: perl-Video-DVDRip
Version: 0.47_04
Release: fr1
License: Artistic
Group: Applications/Multimedia
Source: Video-DVDRip-%{version}.tar.gz
URL: http://www.exit1.org/dvdrip/
BuildRoot: %{_tmppath}/%{name}-root
Requires: transcode, Gtk-Perl, ImageMagick
BuildRequires: Gtk-Perl

%description
dvd::rip is a Perl Gtk+ based DVD copy program built on top of a low level
DVD Ripping API, which uses the Linux Video Stream Processing Tool transcode.

# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl
#%define __find_requires %{SOURCE}

%prep
%setup -q -n Video-DVDRip-%{version}

%build
perl Makefile.PL PREFIX=%{buildroot}%{_prefix}
make

%install
rm -rf %{buildroot}
make install

%clean 
rm -rf %{buildroot}

%files
%defattr(-, root, root)
%{_prefix}/bin/*
%{perl_sitearch}/../Video/DVDRip*
%{_mandir}/man*/*

%changelog
* Sun Oct 13 2002 Michèl Alexandre Salim <salimma1@yahoo.co.uk>
- Modified to compile under Red Hat 8.0
- Update to 0.47_04

* Mon Sep 23 2002 Matthias Saou <matthias.saou@est.une.marmotte.net>
- Update to 0.46.

* Thu Aug  8 2002 Matthias Saou <matthias.saou@est.une.marmotte.net>
- Update to 0.44.
- Added build dependency on Gtk-Perl.

* Tue Jun 25 2002 Matthias Saou <matthias.saou@est.une.marmotte.net>
- Spec file cleanup.

* Sun Jun 16 2002 Nemo <no@one>
- v0.43

* Sun Jun 09 2002 Nemo <no@one>
- v0.42

* Tue May 14 2002 Nemo <no@one>
- v0.40

* Mon May 13 2002 Nemo <no@one>
- v0.39-2
- Michel Alexandre Salim <salimma1@yahoo.co.uk> suggested an improvement in the PATH used by "make test"

* Tue Mar 05 2002 Nemo <no@one>
- bumped up to v0.34

* Tue Feb 19 2002 Nemo <no@one>
- bumped up to v0.33

* Mon Feb 18 2002 Nemo <no@one>
- bumped up to v0.31

* Sun Jan 20 2002 Nemo <no@one>
- bumped up to v0.30

* Sat Jan 19 2002 Nemo <no@one>
- bumped up to v0.29

* Sun Jan 06 2002 Nemo <no@one>
- bumped up to v0.28

* Sat Dec 15 2001 Nemo <no@one>
- First version, v0.25

