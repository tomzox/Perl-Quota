/*
 *   Configuration example for BSD-based systems -
 *   BSDi, FreeBSD, NetBSD, OpenBSD
 *
 *   Ported to BSDI 2.0 by Jim Hribnak (hribnak@nucleus.com) Aug 28 1997
 *   with the help of the original author Tom Zoerner
 *   OpenBSD 2.0 mods provided by James Shelburne (reilly@eramp.net)
 *   FreeBSD mods provided by Kurt Jaeger <pi@complx.LF.net>
 *           and Jon Schewe <schewe@tcfreenet.org>
 *   NetBSD mods and merge of *BSD-related hints provided by
 *           Jaromir Dolecek <jdolecek@NetBSD.org>
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/mount.h>
#include <fstab.h>
#include <ufs/ufs/quota.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpc/svc.h>

#if defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
#include <rpcsvc/rquota.h>
#else /* BSDi */
#include "include/rquota.h"
#endif

#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>

#define Q_DIV(X) ((X) / 2)
#define Q_MUL(X) ((X) * 2)
#define DEV_QBSIZE DEV_BSIZE
#define Q_CTL_V2
#define Q_SETQLIM Q_SETQUOTA
#define CADR (caddr_t)

#define QCARG_MNTPT

#define MY_XDR

#define NO_MNTENT
 
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

