package Quota;

require Exporter;
use AutoLoader;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = ();

$VERSION = '1.1';

bootstrap Quota;

use Carp;
use POSIX qw(:errno_h);

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
##  !! for the quotactl call. i.e. SYS-V and SunOS wants the block device,
##  !! Solaris the pathname of the quotas file on disk, OSF/1 any pathname
##
sub getqcarg {
  ($#_ > 0) && croak("Usage: Quota::getqcarg(path)");
  my($dev) = (stat(($_[0] || ".")))[0];
  my($ret) = undef;
  my($argtyp) = getqcargtype();
  my($fsname,$path,$fstyp);

  if($dev && !Quota::setmntent()) {
    while(($fsname,$path,$fstyp) = Quota::getmntent()) {
      if($dev == (stat($path))[0]) {
	if($fsname !~ m#^/#) { $ret = $fsname }
	elsif($argtyp eq "dev")  { $ret = $fsname }
	elsif($argtyp eq "path") { $ret = "$path/quotas" }
	elsif($argtyp eq "dev(XFS)") {
	  if($fstyp eq "xfs") { $ret = "(XFS)$fsname"; }
	  else { $ret = "$fsname"; }
	}
	else { $ret = $path }  #($argtyp eq "mntpt")
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
##  Translate error codes of quotactl syscall and ioctl
##

sub strerr {
  ($#_ != -1) && croak("Usage: Quota::strerr()");
  my($str);

  eval {
    if(($! == &EINVAL) || ($! == &ENOTTY) || ($! == &ENOENT))
                         { $str = "No quotas on this system" }
    elsif($! == &ENODEV) { $str = "Not a standard file system" }
    elsif($! == &EPERM)  { $str = "Not privileged" }
    elsif($! == &ESRCH)  { $str = "No quota for this user" }
    elsif($! == &EUSERS) { $str = "Quota table overflow" }
    else { die "unknown quota error\n" }
  };
  if($@) {
    my($err) = $! + 0;
    $str = "error #$err";
  };
  $str;
}

package Quota; # return to package Quota so AutoSplit is happy
1;
__END__

=head1 NAME

Quota - Perl interface to file system quotas

=head1 SYNOPSIS

    use Quota;

    ($block_curr, $block_soft, $block_hard, $block_timelimit,
     $inode_curr, $inode_soft, $inode_hard, $inode_timelimit) =
    Quota::query($dev [,$uid]);

    ($block_curr, $block_soft, $block_hard, $block_timelimit,
     $inode_curr, $inode_soft, $inode_hard, $inode_timelimit) =
    Quota::rpcquery($host, $path [,$uid]);

    Quota::setqlim($dev, $uid, $block_soft, $block_hard,
		   $inode_soft, $inode_hard [,$tlo]);

    Quota::sync([$dev]);

    $arg = Quota::getqcarg([$path]);

    Quota::setmntent();
    ($dev, $path, $type, $opts) = Quota::getmntent();
    Quota::endmntent();

=head1 DESCRIPTION

The B<Quota> module provides access to file system quotas.
The quotactl system call or ioctl is used to query or set quotas
on the local host, or queries are submitted via RPC to a remote host.
Mount tables can be parsed with B<getmntent> and paths can be
translated to device files (or whatever the actual B<quotactl>
implementations needs as argument) of the according file system.

=head2 Functions

=over 4

=item I<($bc,$bs,$bh,$bt, $ic,$is,$ih,$it) = Quota::query($dev, $uid)>

Get current usage and quota limits for a given file system and user.
The user is specified by its numeric uid; defaults to the process'
real uid.

The type of I<$dev> varies from system to system. It's the argument
which is used by the B<quotactl> implementation to address a specific
file system. It may be the path of a device file (e.g. B</dev/sd0a>)
or the path of the mount point or the quotas file at the top of
the file system (e.g. B</home.stand/quotas>). However you do not
have to worry about that; use B<Quota::getqcarg> to automatically
translate any path inside a file system to the required I<$dev> argument.

I<$dev> may also be in the form of B<hostname:path>, which has the
module transparently query the given host via a remote procedure call
(RPC). In case you have B<NFS> (or similar network mounts), this type
of argument may also be produced by B<Quota::getqcarg>. Note: RPC
queries require I<rquotad(1m)> to be running on the target system. If
the daemon or host are down, the timeout is 12 seconds.

In I<$bc> and I<$ic> the current usage in blocks and inodes is returned.
I<$bs> and I<$is> are the soft limits, I<$bh> and I<$ih> hard limits. If the
soft limit is exceeded, writes by this user will fail for blocks or
inodes after I<$bt> or I<$it> is reached. These times are expressed
as usual, i.e. in elapsed seconds since 00:00 1/Jan/1970 GMT.

=item I<Quota::setqlim($dev, $uid, $bs,$bh, $is,$ih, $tlo)>

Sets quota limits for the given user. Meanings of I<$dev>, I<$uid>,
I<$bs>, I<$bh>, I<$is> and I<$ih> are the same as in B<Quota::query>.

I<$tlo> decides how the time limits are initialized:
I<0>: The time limits are set to B<NOT STARTED>, i.e. the time limits
are not initialized until the first write attempt by this user.
This is the default.
I<1>: The time limits are set to B<7.0 days>.
More alternatives (i.e. setting a specific time) aren't available in
most implementations.

Note: if you want to set the quota of a particular user to zero, i.e.
no write permission, you must not set all limits to zero, since that
is equivalent to unlimited access. Instead set only the hard limit
to 0 and the soft limit for example to 1.

Note that you cannot set quotas via RPC.

=item I<Quota::sync($dev)>

Have the kernel update the quota file on disk or all quota files
if no argument given (the latter doesn't work on all systems,
in particular on B<HP-UX 10.10>).

The main purpose of this function is to check if quota is enabled
in the kernel and for a particular file system. Read the B<quotaon(1m)>
man page on how to enable quotas on a file system.

=item I<($bc,$bs,$bh,$bt, $ic,$is,$ih,$it) =>

I<Quota::rpcquery($host,$path,$uid)>

This is equivalent to B<Quota::query("$host:$path",$uid)>, i.e.
query quota for a given user on a given remote host via RPC.
I<$path> is the path of any file or directory inside the wanted
file system on the remote host.

=item I<$arg = Quota::getqcarg($path)>

Get the required I<$dev> argument for B<Quota::query> and B<Quota::setqlim>
for the file system you want to operate on. I<$path> is any path of an
existing file or directory inside that file system. The path argument is
optional and defaults to the current working directory.

The type of I<$dev> varies between operating systems, i.e. different
implementations of the quotactl functionality. Hence it's important for
compatibility to always use this module function and not really pass
a device file to B<Quota::query> (as returned by B<Quota::getdev>).
See also above at I<Quota::query>

=item I<$dev = Quota::getdev($path)>

Returns the device entry in the mount table for a particular file system,
specified by any path of an existing file or directory inside it. I<$path>
defaults to the working directory. This device entry need not really be
a device. For example on network mounts (B<NFS>) it's I<"host:mountpath">,
with I<amd(1m)> it may be something completely different.

I<NEVER> use this to produce a I<$dev> argument for other functions of
this module, since it's not compatible. On some systems I<quotactl>
does not work on devices but on the I<quotas> file or some other kind of
argument. Always use B<Quota::getqcarg>.

=item I<Quota::setmntent()>

Opens or resets the mount table. This is required before the first
invocation of B<Quota::getmntent>.

Note: on some systems there is no equivalent function in the C library.
But you still have to call this module procedure for initialization of
module-internal variables.

=item I<($dev, $path, $type, $opts) = Quota::getmntent()>

Returns the next entry in the system mount table. This table contains
information about all currently mounted (local or remote) file systems.
The format and location of this table (e.g. B</etc/mtab>) vary from
system to system. This function is provided as a compatible way to
parse it. (On some systems, like B<OSF/1>, this table isn't
accessible as a file at all, i.e. only via B<Quota::getmntent>).

=item I<Quota::endmntent()>

Close the mount table. Should be called after the last use of
B<Quota::getmntent> to free possibly allocated file handles and memory.
Always returns undef.

=item I<Quota::strerr()>

Translates B<$!> to a quota-specific error text. You should always
use this function to output error messages, since the normal messages
don't always make sense for quota errors
(e.g. I<ESRCH>: B<No such process>, here: B<No quota for this user>)

=head1 RETURN VALUES

Functions that are supposed return lists or scalars, return I<undef> upon
errors. As usual B<$!> contains the error code (see B<Quota::strerr>).

B<Quota::endmntent> always returns I<undef>. All other functions return
I<undef> only upon errors.

=head1 EXAMPLES

An example for each function can be found in the test script
I<test/quotatest>. See also the contrib directory, which contains
some longer scripts, kindly donated by users of the module.

=head1 BUGS

With remote quotas we have to rely on the remote system to state
correctly which block size the quota values are referring to.
Unfortunately on Linux the rpc.rquotad reports a block size of
4 kilobytes, which is wildly incorrect. So you either need to fix
your Linux rquotad or keep B<#define LINUX_RQUOTAD_BUG> defined,
which will Quota::query always let assume all remote partners
in reality report 1kB blocks. Of course that'll break with mixed
systems, so better fix your rquotad.

=head1 AUTHOR

This module was written 1995 by Tom Zoerner
(Tom.Zoerner@informatik.uni-erlangen.de)

Additional testing and porting by
David Lee (T.D.Lee@durham.ac.uk),
Tobias Oetiker (oetiker@ee.ethz.ch),
Jim Hribnak (hribnak@nucleus.com),
David Lloyd (cclloyd@monotreme.cc.missouri.edu),
James Shelburne (reilly@eramp.net) and
Subhendu Ghosh (sghosh@menger.eecs.stevens-tech.edu).
Special thanks go to Steve Nolan at bookmark.com for providing
me with an account and hence finally allowing me to finish the
Linux port.

=head1 SEE ALSO

perl(1), edquota(1m),
quotactl(2) or quotactl(7I),
mount(1m), mtab(4) or mnttab(4), quotaon(1m),
setmntent(3), getmntent(3) or getmntinfo(3), endmntent(3),
rpc(3), rquotad(1m).

=cut
