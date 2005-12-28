# $Id: FixLocaleTextDomainUTF8.pm,v 1.1 2005/12/26 14:37:15 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2003 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::FixLocaleTextDomainUTF8;

use Locale::TextDomain ("video.dvdrip");
use POSIX  qw(setlocale LC_MESSAGES);
use Encode qw(_utf8_on);

my $utf8_locale_in_effect = setlocale(LC_MESSAGES) =~ /utf-?8/i;

sub utf8_fix__ ($) {
    my ($msgid) = @_;
    my $rc = __($msgid);
    _utf8_on($rc);
    return $rc;
}

sub utf8_fix__x ($@) {
    my ($msgid, %vars) = @_;
    if ( wantarray ) {
        my @rc = __x($msgid, %vars);
        _utf8_on($_) for @rc;
        return @rc;
    }
    else {
        my $rc = __x($msgid, %vars);
        _utf8_on($rc);
        return $rc;
    }
}

sub utf8_fix__n ($@) {
    my ($msgid, $msgid_plural, $count) = @_;
   if ( wantarray ) {
        my @rc = __n($msgid, $msgid_plural, $count);
        _utf8_on($_) for @rc;
        return @rc;
    }
    else {
        my $rc = __n($msgid, $msgid_plural, $count);
        _utf8_on($rc);
        return $rc;
    }
}

sub import {
    #-- nothing to export if we don't have an UTF-8 locale
    return unless $utf8_locale_in_effect;
    
    #-- otherwise overwrite Locale::TextDomain's exports
    #-- with the utf8 fixing versions from this module
    my $callpkg = (caller)[0];
    *{$callpkg."::__"}  = \&utf8_fix__;
    *{$callpkg."::__x"} = \&utf8_fix__x;
    *{$callpkg."::__n"} = \&utf8_fix__n;
    
    1;
}

1;
