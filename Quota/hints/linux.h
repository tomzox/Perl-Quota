/*
 *   Configuration for Linux - kernel version 2.0.22 and later
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/types.h>
/* #include <linux/types.h> */
/* <asm/types.h> is required only on some distributions (Debian 2.0, RedHat)
   if your's doesn't have it you can simply remove the following line */
#include <asm/types.h>
#include <linux/quota.h>
#include <sys/syscall.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
/* #include "include/rquota.h" */
#include <sys/socket.h>
#include <netdb.h>

#include <strings.h>
#include <stdio.h>

/* Heuristic check for the new Quota API V2 */
#if defined(INITQFNAMES) && (Q_GETQUOTA==0x0D00)
/* declare the v1 quota block struct */
struct dqblk {
  __u32 dqb_bhardlimit;   /* absolute limit on disk blks alloc */
  __u32 dqb_bsoftlimit;   /* preferred limit on disk blks */
  __u32 dqb_curblocks;    /* current block count */
  __u32 dqb_ihardlimit;   /* absolute limit on allocated inodes */
  __u32 dqb_isoftlimit;   /* preferred inode limit */
  __u32 dqb_curinodes;    /* current # allocated inodes */
  time_t dqb_btime;       /* time limit for excessive disk use */
  time_t dqb_itime;       /* time limit for excessive inode use */
};
#else
typedef u_int64_t qsize_t;
#endif

int linuxquota_query( const char * dev, int uid, int isgrp, struct dqblk * dqb );
int linuxquota_setqlim( const char * dev, int uid, int isgrp, struct dqblk * dqb );


#define Q_DIV(X) (X)
#define Q_MUL(X) (X)
#define DEV_QBSIZE 1024

#define Q_CTL_V3
#define CADR (caddr_t)

#define MY_XDR

#define MNTENT mntent

#define GQR_STATUS status
#define GQR_RQUOTA getquota_rslt_u.gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_ihardlimit
#define QS_FSOFT dqb_isoftlimit
#define QS_FCUR  dqb_curinodes
#define QS_BTIME dqb_btime
#define QS_FTIME dqb_itime

/* uncomment this is you're using NFS with a version of the quota tools < 3.0 */
/* #define LINUX_RQUOTAD_BUG */

/* optional: for support of SGI XFS file systems - comment out if not needed */
#define SGI_XFS
#define QX_DIV(X) ((X) >> 1)
#define QX_MUL(X) ((X) << 1)
#include "include/quotaio_xfs.h"


/* MakeMaker parameters for AFS support - do not remove!
MAKE AFSHOME=/products/security/athena
MAKE INC=-I$(AFSHOME)/include
MAKE OBJ=afsquota.o afssys.o
## Linux does not record LD_RUN_PATH within DLOs, so we do without shlibs
## and extract the required object from the lib to link statically
MAKE ARXLIBOBJ=$(AFSHOME)/lib/libkafs.a afssys.o
*/
