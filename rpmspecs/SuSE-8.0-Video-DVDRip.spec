##############################################################
# define here the version - prerelease stuff
%define prerelease %nil
%define version 0.48.0
# myrelease >=1 !
%define myrelease 1
##############################################################

%if "%{prerelease}" == ""
	%define release %{myrelease}
%else
	%define release 0.pre%{prerelease}_%{myrelease}
%endif

%define source_version %{version}%{prerelease}

Summary: Video-DVDRip module for perl 
Name:		perl-Video-DVDRip
Version:	%version
Release:	%release
Copyright:	distributable
Group:		Applications/CPAN
%if "%{prerelease}" == ""
Source:		http://www.exit1.org/dvdrip/dist/Video-DVDRip-%{source_version}.tar.gz
%else
Source:		http://www.exit1.org/dvdrip/dist/pre/Video-DVDRip-%{source_version}.tar.gz
%endif
Url:		http://www.exit1.org/dvdrip/
BuildRoot:	%{_tmppath}/buildroot-%{name}
Requires:	transcode >= 0.6.2
Requires:       mjpegtools >= 1.6.0    
Requires:       perl-Gtk-Perl
Requires:       ps

%description
dvd::rip is a Perl Gtk+ based DVD copy program build on top of a low level DVD Ripping API, 
which uses the Linux Video Stream Processing Tool transcode, written by Thomas Östreich.
    

%package cluster    
Summary:        Cluster support for Video-DVDRip
Group:		Applications/CPAN
Requires:	%{name} = %{version}
Requires:       fping
Requires:       ps

%description cluster    
The cluster package for Videos-DVDRip should ensure, that the installtion is OK for
the cluster mode.
  
# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%prep
%setup -q -n Video-DVDRip-%{source_version}

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

%files -f Video-DVDRip-%{version}-filelist
%defattr(-,root,root)

%files cluster
%defattr(-,root,root)

%changelog
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

