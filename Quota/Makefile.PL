#!../../perl

chop($os = `uname -rs 2>/dev/null`);
if($os =~ /^SunOS 4\.1/) { $config='sunos_4_1.h'; }
elsif($os =~ /^SunOS 5/) { $config='solaris_2.h'; }
elsif($os =~ /^HP-UX (A\.09|B\.10)/) { $config='hpux_9+10.h'; }
elsif($os =~ /^IRIX 5/)  { $config='irix_5.h'; }

printf "Using hints/$config for config.h\n" if defined($config);

###--------------------------------------------------------------------------#
### You shouldn't need to change anything below
###

BEGIN { push(@INC, "../../lib"); }

use ExtUtils::MakeMaker;

&WriteMakefile('NAME'         => 'Quota',
	       'INC'          => "",
	       'LIBS'         => [ '-lrpcsvc' ],
	       'H'            => [ 'config.h' ],
	       'VERSION_FROM' => 'Quota.pm',
	       'clean'        => { FILES => 'config.h' },
);

sub MY::postamble
{
    if(!defined $config) {
      '
config.h:
	@echo "You need to make a config.h.  See the INSTALL document.";
	@false
      '
    }
    else {
      "
config.h:
	if [ ! -r config.h ] ; then ln -s hints/$config config.h; fi
      "
    }
}
