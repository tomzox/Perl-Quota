/*
 *   Configuration for 6.2 - 6.4
 *   (the only difference to IRIX 5 is XFS and AFS support)
 *
 *   If you use XFS with IRIX 6.2 you *must* install the latest xfs patch sets!
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <unistd.h>
#include <stdio.h>

#include <sys/param.h>
#include <sys/types.h>
/* For IRIX 6.5.1 you might need the following hack */
/* #define __SYS_SEMA_H__ */
#include <sys/quota.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>

#define Q_DIV
#define Q_MUL
#define DEV_QBSIZE DEV_BSIZE
#define CADR (caddr_t)

#define MNTENT mntent

#define GQR_STATUS gqr_status
#define GQR_RQUOTA gqr_rquota

#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_fhardlimit
#define QS_FSOFT dqb_fsoftlimit
#define QS_FCUR  dqb_curfiles
#define QS_BTIME dqb_btimelimit
#define QS_FTIME dqb_ftimelimit

/* optional: for support of XFS file systems - comment out if not needed */
#define IRIX_XFS


/* MakeMaker parameters for AFS support - do not remove!
MAKE AFSHOME=/products/security/athena
MAKE LDLOADLIBS=-L$(AFSHOME)/lib32 -lkafs -ldes -lkrb -rpath $(AFSHOME)/lib32 -lrpcsvc
MAKE INC=-I$(AFSHOME)/include
MAKE OBJ=afsquota.o
*/
