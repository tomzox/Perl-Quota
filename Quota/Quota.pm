package Quota;

require Exporter;
use AutoLoader;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = ();

$VERSION = '0.3a';

bootstrap Quota;

use Carp;
require 'errno.ph'; eval '&EPERM;'; &strerr_defs if $@;

##
##  Get block device for locally mounted file system
##

sub getdev {
  ($#_ > 0) && croak("Usage: Quota::getdev(path)");
  my($dev) = (stat(($_[0] || ".")))[0];
  my($ret) = undef;
  my($fsname,$path);
 
  if($dev && !Quota::setmntent()) {
    while(($fsname,$path) = Quota::getmntent()) {
      ($ret=$fsname, last) if ($dev == (stat($path))[0]);
    }
    $! = 0;
  }
  Quota::endmntent();
  $ret;
}

##
##  Get "dev" argument for Quota-functions in this module
##  !! Not all operating systems require the same type of info as parameter
##  !! for the quotactl call. i.e. SYS-V and BSD wants the block device,
##  !! Solaris the pathname of the quotas file on disk, OSF/1 any pathname
##
sub getqcarg {
  ($#_ > 0) && croak("Usage: Quota::getqcarg(path)");
  my($dev) = (stat(($_[0] || ".")))[0];
  my($ret) = undef;
  my($argtyp) = getqcargtype();
  my($fsname,$path);

  if($dev && !Quota::setmntent()) {
    while(($fsname,$path) = Quota::getmntent()) {
      if($dev == (stat($path))[0]) {
	if($fsname !~ m#^/#) { $ret = $fsname }
	elsif($argtyp eq "dev")  { $ret = $fsname }
	elsif($argtyp eq "path") { $ret = "$path/quotas" }
	else { $ret = $path }
        last;
      }
    }
    $! = 0;
  }
  Quota::endmntent();
  return ($_[0] || ".") if ($argtyp eq "path") && ($ret =~ m#^/#);
  $ret;
}

##
##  Translate error codes of quotactl syscall
##

sub strerr {
  ($#_ != -1) && croak("Usage: Quota::strerr()");
  my($str);

  if(($! == &EINVAL) || ($! == &ENOTTY)) { $str = "No quotas on this system" }
  elsif($! == &ENODEV) { $str = "Not a standard file system" }
  elsif($! == &EPERM)  { $str = "Not privileged" }
  elsif($! == &ESRCH)  { $str = "No quota for this user" }
  elsif($! == &EUSERS) { $str = "Quota table is full" }
  else { $str = "$!" }
  $str;
}

##  only in case the require for errno fails
##  this is ridiculous, but I didn't get it to work with HP-UX 10.10

sub strerr_defs {
  eval 'sub EPERM {1;}';
  eval 'sub ESRCH {3;}';
  eval 'sub ENODEV {19;}';
  eval 'sub EINVAL {22;}';
  eval 'sub ENOTTY {25;}';
  eval 'sub EUSERS {68;}';
}

package Quota; # return to package Quota so AutoSplit is happy
1;
__END__

