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

foreach (@Mtab)
{
   $path = (split(/#/))[2];
   $qcarg = Quota::getqcarg($path);
   print "$_#$qcarg#\n";
}
