Summary: Video-DVDRip module for perl 
Name:		perl-Video-DVDRip
Version:	0.46
Release:	2
License:	Distributable
Group:		Applications/CPAN
Source0:	Video-DVDRip-%{version}.tar.gz
Url:		http://www.exit1.org/dvdrip/
BuildRoot:	%{_tmppath}/%{name}-root
Requires:	transcode, Gtk-Perl
Provides:	perl(Video::DVDRip::GUI::Project::ClipZoomTab), perl(Video::DVDRip::GUI::Project::LoggingTab), perl(Video::DVDRip::GUI::Project::StorageTab), perl(Video::DVDRip::GUI::Project::TitleTab), perl(Video::DVDRip::GUI::Project::TranscodeTab)


%description
Video-DVDRip module for perl

# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%prep
%setup -q -n Video-DVDRip-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS" perl Makefile.PL PREFIX="$RPM_BUILD_ROOT/usr"
make
PATH=.:$PATH make test

%clean 
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make PREFIX=$RPM_BUILD_ROOT/usr install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find $RPM_BUILD_ROOT/usr -name perllocal.pod -or -name .packlist | xargs rm

find $RPM_BUILD_ROOT/usr -type f -print | 
	sed "s@^$RPM_BUILD_ROOT@@g" > Video-DVDRip-%{version}-filelist
echo 2
if [ "$(cat Video-DVDRip-%{version}-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi
echo 3

%files -f Video-DVDRip-%{version}-filelist
%defattr(-,root,root)

%changelog
* Mon Oct 28 2002 Ragnark Kjørstad <dvdrip@ragnark.vestdata.no>
- Updated to rpm v4.2 compatible spec-file

* Sun Sep 22 2002 Nemo <no@one>
- v0.46

* Sun Jul 21 2002 Nemo <no@one>
- v0.44

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
