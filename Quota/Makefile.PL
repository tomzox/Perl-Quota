#!/local/bin/perl5
#
# You should define two perl variables:
#
#    $inc    contains any includes or defines (-I or -D) that are
#               needed to compile libcurses applications
#    $libs   contains any libraries or library paths (-l or -L) that are
#               needed to compile libcurses applications
#
# You can choose include and libraries here
# Shouldn't be neccessary on most systems

# SunOS, Solaris 2.4, IRIX 5.3
$inc  = "";
$libs = "-lrpcsvc";

# HP-UX 9.01 has no shared RPC library, so we include our own
# $inc  = "";
# $libs = "";

###--------------------------------------------------------------------------#
### You shouldn't need to change anything below
###

BEGIN { push(@INC, "../../lib"); }

use ExtUtils::MakeMaker;

&WriteMakefile(NAME      => 'Quota',
	       INC       => $inc,
	       LIBS      => [ $libs ],
	       H         => [ 'config.h' ],
	       VERSION   => 'a0',
	       clean     => { FILES => 'config.h' },
);

sub MY::postamble
{
    '
config.h:
	@echo "You need to make a config.h.  See the INSTALL document.";
	@false
    '
}
