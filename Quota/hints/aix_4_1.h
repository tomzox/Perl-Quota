/*
 *   Configuration for AIX 4.1
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */


#include <sys/param.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include "include/rquota.h"

#include <jfs/quota.h>
#include <sys/mntctl.h>
#include <sys/vmount.h>

#define AIX
#define Q_CTL_V2

#define Q_DIV
#define Q_MUL
#define DEV_QBSIZE DEV_BSIZE

#define CADR (caddr_t)

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


/* Uncomment the following define and MAKE lines to enable AFS support */

/* #define AFSQUOTA */

/* MakeMaker parameters - do not remove!
#MAKE AFSHOME=/products/security/athena
#MAKE LDLOADLIBS=-L$(AFSHOME)/lib -lkafs -ldes -lkrb -lroken -lld -lrpcsvc
#MAKE INC=-I$(AFSHOME)/include
#MAKE OBJ=afsquota.o
*/
