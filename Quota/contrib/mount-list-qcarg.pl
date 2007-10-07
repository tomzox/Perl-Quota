#!/usr/bin/perl

use blib;
use Quota;

my($fsname,$path,$fstyp);

if(!Quota::setmntent()) {
   while(($fsname,$path,$fstyp) = Quota::getmntent())
   {
      push(@Mtab, "#$fsname#$path#$fstyp#");
   }
}
Quota::endmntent();

print Quota::getqcargtype() ."\n\n";

foreach (@Mtab)
{
   $path = (split(/#/))[2];
   $qcarg = Quota::getqcarg($path);
   $qcarg = "*UNDEF*" unless defined $qcarg;
   $dev = (stat($path))[0];
   print "${_}$qcarg#$dev\n";
}
