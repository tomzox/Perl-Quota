
/*
 *   Configuration example for unknown OS
 */

#include <sys/param.h>

/* This is needed for the quotactl syscall. See man quotactl(2) */
#include <ufs/quota.h>

/* This is needed for the mntent library routines. See man getmntent(3)
   another probable name is mnttab or mtab. Basically that's the name
   of the file where mount(1m) keeps track of the current mounts.
   See FILES section of man mount for the name of that file */
#include <mntent.h>

/* See includes list man callrpc(3) and man rquota(3) */
#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>

/* Select one of the following, preferring the first */
#include <rpcsvc/rquota.h> /**/
/* #include "include/rquota.h" /**/

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

/* define if you don't want the RPC query functionality,
   i.e. you want to operate on the local host only */
/* #define NO_RPC /**/

/* This is for systems that lack librpcsvc and don't have xdr_getquota_args
   et. al. in libc either. If you do have /usr/include/rpcsvc/rquota.x
   you can generate these routines with rpcgen, too */
/* #define MY_XDR /**/

/* needed only if MOUNTED is not defined in <mnttab.h> (see above) */
/* define MOUNTED mnttab /**/

/* name of the structure used by getmntent(3) */
#define MNTENT mntent

/* on some systems setmntent/endmntend do not exist  */
/* #define NO_OPEN_MNTTAB /**/

/* if your system doesn't have /etc/mnttab, and hence no getmntent,
   use getmntinfo instead then (e.g. in OSF) */
/* #define NO_MNTENT /**/

/* name of the status entry in struc getquota_rslt and
   name of the struct or union that contains the quota values.
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

