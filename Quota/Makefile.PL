#!/usr/local/bin/perl

# You shouldn't need to change anything here.
# All configuration is done in the hints/ directory.
#-----------------------------------------------------------------------------#
#
# Automagically choose the right configuration
#
chop($os = `uname -rs 2>/dev/null`);
if   ($os =~ /^SunOS 4\.1/){ $config='sunos_4_1.h'; }
elsif($os =~ /^SunOS 5/)   { $config='solaris_2.h'; }
elsif($os =~ /^HP-UX (A\.09|B\.10|[BC]\.11)/) { $config='hpux.h'; }
elsif($os =~ /^IRIX 5/)    { $config='irix_5.h'; }
elsif($os =~ /^IRIX\d* 6/) { $config='irix_6.h'; }
elsif($os =~ /^OSF1/)      { $config='dec_osf.h'; }
elsif($os =~ /^Linux 2/)   { $config='linux.h'; $extraobj='linuxapi.o'; }
elsif($os =~ /^AIX/)       { $config='aix_4_1.h'; }
elsif($os =~ /^BSD\/OS 2/ ||
      $os =~ /^FreeBSD/   ||
      $os =~ /^NetBSD/    ||
      $os =~ /^OpenBSD/)   { $config='bsd.h'; }

if (defined($config)) {
  print "Using hints/$config for myconfig.h\n";
  if (-e "myconfig.h" && (!(-l "myconfig.h") || (readlink("myconfig.h") ne "hints/$config"))) {
     die "\nFATAL: myconfig.h already exists.\n\n" .
         "You need to do a `make clean' before you configure for a new platform.\n".
	 "If that doesn't help, remove myconfig.h manually.\n";
  }
}
else {
  warn "WARNING: No appropriate hints found for this OS: '$os - see INSTALL'\n";
}


# check whether the Andrew File System (AFS) is installed and running

if ( -d "/afs" ) {
  my $afs = `df /afs 2>/dev/null`;
  if ($afs =~ /\nAFS|\(AFS/) {
    $hasafs = '-DAFSQUOTA';

    # extract further parameters from the hints file
    if (open(HINTS,"<hints/$config")) {
      while(<HINTS>) {
        if (/^MAKE\s+([^=]+)=(.*)/) { $hint{$1} = $2; }
      }
      close(HINTS);
    }
    else { warn "cannot open hints file $config: $!\n"; }
  }
}

# check to see if we have a kernel module for the Veritas file system
if ( $os =~ /^SunOS/ ) {
   if ( -f '/kernel/fs/vxfs' ) {
     $hasvxfs = '-DSOLARIS_VXFS';
     $extraobj = "$extraobj vxquotactl.o";
     print "Configured with the VERITAS File System on Solaris\n";
   }
   else {
     print "Configured without VxFS support\n";
   }
}

#-----------------------------------------------------------------------------#

use ExtUtils::MakeMaker;

&WriteMakefile('NAME'         => 'Quota',
               'OBJECT'       => '$(BASEEXT)$(OBJ_EXT) stdio_wrap.o '.
                                 $extraobj .' '. $hint{'OBJ'},
               'INC'          => $hint{'INC'},
               'DEFINE'       => "$hasafs $hasvxfs",
               'LIBS'         => [ '-lrpcsvc' ],
               'H'            => [ 'myconfig.h' ],
               'VERSION_FROM' => 'Quota.pm',
               'clean'        => { FILES => 'myconfig.h' },
);


#
#  Set parameters for AFS shared libs
#

sub MY::post_constants
{
    my $ret = '';

    foreach (qw(AFSHOME EXTRALIBS LDLOADLIBS BSLOADLIBS LD_RUN_PATH)) {
      if (defined($hint{$_})) {
        $ret .= "$_ = $hint{$_}\n";
      }
    }
    if ($ret eq '') {
      print "Configured without AFS support\n";
    }
    $ret;
}

#
#  Add rules for hints (myconfig.h)
#  and extra objects that need special compiler arguments
#

sub MY::postamble
{
    my $ret = '';
    my $extrac;

    if(!defined $config) {
      $ret .= '
myconfig.h:
	@echo "You need to make a myconfig.h.  See the file INSTALL.";
	@false
'
    }
    else {
      $ret .= "
myconfig.h:
	rm -f myconfig.h
	ln -s hints/$config myconfig.h
"
    }

    # objects that must not be compiled with the CCCDL arguments

    if (defined $extraobj) {
        ($extrac = $extraobj) =~ s/\.o(\s+|$)/.c/g;
        $ret .= "\n$extraobj :\n\t".
                '$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) '."$extrac\n\n";
    }

    # extract objects from a library to link them in statically
    # for lame OSes that have problems with LD_PATH recording in DLOs

    if (defined $hint{'ARXLIBOBJ'}) {
        $hint{'ARXLIBOBJ'} =~ /\s+/;
        $ret .= "\n$' :\n\t\$(AR) x " . $hint{'ARXLIBOBJ'} ."\n\n";
    }

    $ret;
}
