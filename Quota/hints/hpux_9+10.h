/*
 *   Configuration for HP-UX 9.0.x & HP-UX 10.10 & HP-UX 10.20
 *
 *   For AFS support look at the end of this file
 */

/*   See hints/none.h for a complete list of options with explanations */

#include <sys/param.h>
#include <sys/quota.h>
#include <sys/vfs.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>

#define Q_DIV
#define Q_MUL
#define DEV_QBSIZE DEV_BSIZE
#define CADR (caddr_t)

#define MNTENT mntent

/*  HP-UX has no shared librpcsvc. So we need to include the
 *  XDR routines supplied with this module.
 */
#define MY_XDR

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


/* Uncomment the following define and MAKE lines to enable AFS support */

/* #define AFSQUOTA */

/* MakeMaker parameters - do not remove!
#MAKE AFSHOME=/products/security/athena
#MAKE LDLOADLIBS=-L$(AFSHOME)/lib -lkafs -ldes -lkrb
#MAKE INC=-I$(AFSHOME)/include
#MAKE OBJ=afsquota.o
*/
