%define version 0.50.14
%define release 0

Summary: Video-DVDRip module for perl 
Name:		perl-Video-DVDRip
Version:	%version
Release:	%release
Copyright:	distributable
Group:		Applications/CPAN
Source:		http://www.exit1.org/dvdrip/dist/Video-DVDRip-%{version}.tar.gz
Url:		http://www.exit1.org/dvdrip/
BuildRoot:	%{_tmppath}/buildroot-%{name}
Requires:	transcode >= 0.6.2
Requires:       mjpegtools >= 1.6.0    
Requires:       perl-Gtk-Perl
Requires:       ps

%description
dvd::rip is a full featured DVD copy program written in Perl.
It provides an easy to use but feature-rich Gtk+ GUI to control
almost all aspects of the ripping and transcoding process.
It uses the widely known video processing swissknife transcode
and many other Open Source tools.

%package cluster    
Summary:        Cluster support for Video-DVDRip
Group:		Applications/CPAN
Requires:	%{name} = %{version}
Requires:       fping
Requires:       ps

%description cluster    
The cluster package for Videos-DVDRip should ensure, that the
installation is OK for the cluster mode.
  
# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%prep
%setup -q -n Video-DVDRip-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS" perl Makefile.PL
make
make test

%clean 
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
rm -rf $RPM_BUILD_DIR/Video-DVDRip-%{version}

%install
rm -rf $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make PREFIX=$RPM_BUILD_ROOT/usr install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find $RPM_BUILD_ROOT/usr -type f -print | 
	sed "s@^$RPM_BUILD_ROOT@@g" | 
	grep -v perllocal.pod | 
	grep -v "\.packlist" > Video-DVDRip-%{version}-filelist
if [ "$(cat Video-DVDRip-%{version}-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi

%pre cluster
test `/bin/ls -la /usr/sbin/fping | cut -c4-4` != s 
[ $? = 0 ] && echo "/usr/sbin/fping should be suid root! You can do this with 'chmod +s /usr/sbin/fping'"
[ $? = 1 ] && /bin/true

%post
# Kde3
if test -d /opt/kde3/share/applnk/Multimedia; then
    echo -e "[Desktop Entry]\12Encoding=UTF-8\12Name=Video-DVDRip\12Exec=dvdrip\12Icon=package_multimedia\12Type=Application\12GenericName=dvd::rip\12Terminal=0" > /opt/kde3/share/applnk/Multimedia/Video-DVDRip.desktop
    chmod 755 /opt/kde3/share/applnk/Multimedia/Video-DVDRip.desktop
fi
# End Kde3
# Kde2
if test -d /opt/kde2/share/applnk/Multimedia; then
    echo -e "[Desktop Entry]\12Encoding=UTF-8\12Name=Video-DVDRip\12Exec=dvdrip\12Icon=package_multimedia\12Type=Application\12GenericName=dvd::rip\12Terminal=0" > /opt/kde2/share/applnk/Multimedia/Video-DVDRip.desktop
    chmod 755 /opt/kde2/share/applnk/Multimedia/Video-DVDRip.desktop
fi
# End Kde2

%preun
  # KDE 2 Desktopeintrag entfernen
  rm -f /opt/kde2/share/applnk/Multimedia/Video-DVDRip.desktop
  # KDE 3 Desktopeintrag entfernen
  rm -f /opt/kde3/share/applnk/Multimedia/Video-DVDRip.desktop

%files -f Video-DVDRip-%{version}-filelist
%defattr(-,root,root)

%files cluster
%defattr(-,root,root)

%changelog
* Thu Nov 21 2002 Rainer Lay <rainer.lay@cs.fau.de> 0.48.0-1
- adepted to new naming scheme

* Sun Oct  6 2002  <rainer.lay@cs.fau.de> 0.47
- added ps for std package

* Mon Aug  5 2002 Rainer Lay <rainer.lay@gmx.de>
- changed requires of transcode for 0.6.0
    
* Mon May 27 2002 Rainer Lay <rainer.lay@gmx.de>
- changed naming scheme for prereleases
    
* Tue Apr  2 2002 Rainer Lay <rainer@faui6lx1.informatik.uni-erlangen.de>
- version 0.38
    
* Mon Mar 25 2002 Rainer Lay <rainer.lay@gmx.de>
- 38_01
    
* Wed Mar 13 2002 Nemo <no@one>
- bumped up to v0.35

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

