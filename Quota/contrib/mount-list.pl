#!/usr/bin/perl

use blib;
use Quota;

my($fsname,$path,$fstyp);

if(!Quota::setmntent()) {
   while(($fsname,$path,$fstyp) = Quota::getmntent())
   {
      print "#$fsname#$path#$fstyp#\n";
   }
}
Quota::endmntent();

