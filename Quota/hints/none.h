
/*
 *   Configuration example for unknown OS
 */

#include <sys/param.h>

/* This is needed for the quotactl syscall. See man quotactl(2) */
#include <ufs/quota.h>

/* This is needed for the mntent library routines. See man getmntent(3) */
#include <mntent.h>

/* See man callrpc(3) and man rquota(3) */
#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>

/* See man socket(2) and man gethostbyname(3) */
#include <sys/socket.h>
#include <netdb.h>

/* Needed for definition of type FILE for set/getmntent(3) routines */
#include <stdio.h>

/* These values depend on the blocksize of your filesystem.
   Scale it the way, that quota values are in kB */
#define Q_DIV / 2
#define Q_MUL * 2

/* Some systems need to cast the dqblk structure
   Do change only if your compiler complains */
#define CADR (caddr_t)

/* define if you don't want the rpcquery functionality */
/* #define NO_RPC /* */

/* define if you don't have a shared librpcsvc library
   this includes the needed xdr routines from within this module */
/* #define MY_RPC /* */

/* name of the structure used by getmntent(3) */
#define MNTENT mntent
 
/* name of the status entry in struc getquota_rslt and
   name of the struc or union that contains the quota values.
   see include <rpcsvc/rquota.h> */
#define GQR_STATUS gqr_status
#define GQR_RQUOTA gqr_rquota

/* members of the dqblk structure, see the include named in man quotactl */
#define QS_BHARD dqb_bhardlimit
#define QS_BSOFT dqb_bsoftlimit
#define QS_BCUR  dqb_curblocks
#define QS_FHARD dqb_fhardlimit
#define QS_FSOFT dqb_fsoftlimit
#define QS_FCUR  dqb_curfiles
#define QS_BTIME dqb_btimelimit
#define QS_FTIME dqb_ftimelimit

