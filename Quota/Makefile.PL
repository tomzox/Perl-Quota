#!../../perl

# You shouldn't need to change anything here.
# All configuration is done in the hints/ directory.
#-----------------------------------------------------------------------------#
#
# Automagically choose the right configuration
#
chop($os = `uname -rs 2>/dev/null`);
if($os =~ /^SunOS 4\.1/) { $config='sunos_4_1.h'; }
elsif($os =~ /^SunOS 5/) { $config='solaris_2.h'; }
elsif($os =~ /^HP-UX (A\.09|B\.10)/) { $config='hpux_9+10.h'; }
elsif($os =~ /^IRIX 5/)  { $config='irix_5.h'; }
elsif($os =~ /^IRIX 6/)  { $config='irix_6.h'; }
elsif($os =~ /^OSF1 V3/) { $config='dec_osf_3.h'; }
elsif($os =~ /^BSD\/OS 2/) { $config='bsdi_2.h'; }
elsif($os =~ /^Linux 2/) { $config='linux.h'; $extraobj='quotactl.o';}

printf "Using hints/$config for config.h\n" if defined($config);

#-----------------------------------------------------------------------------#

BEGIN { push(@INC, "../../lib"); }

use ExtUtils::MakeMaker;

&WriteMakefile('NAME'         => 'Quota',
	       'OBJECT'       => '$(BASEEXT)$(OBJ_EXT) stdio_wrap.o '.$extraobj,
	       'INC'          => '',
	       'LIBS'         => [ '-lrpcsvc' ],
	       'H'            => [ 'config.h' ],
	       'VERSION_FROM' => 'Quota.pm',
	       'clean'        => { FILES => 'config.h' },
);

sub MY::postamble
{
    my $ret = '';

    if(!defined $config) {
      $ret .= '
config.h:
	@echo "You need to make a config.h.  See the INSTALL document.";
	@false
      '
    }
    else {
      $ret .= "
config.h:
	rm -f config.h
	ln -s hints/$config config.h
      "
    }
    if (defined $extraobj) {
	($extrac = $extraobj) =~ s/\.o(\s+|$)/.c/g;
        $ret .= "\n$extraobj :\n\t".
                '$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) '."$extrac\n\n";
    }
    $ret;
}
