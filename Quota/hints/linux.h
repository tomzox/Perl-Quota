
/*
 *   Configuration for Linux 2.0.22
 */

/*
 *   This should compile without problems. However I can't test it
 *   since I don't have access to a Linux system with quota support.
 *   If it doesn't work, uncomment #define NO_RPC below.
 *   Mail me any results   -tom
 */

#include <sys/param.h>
#include <sys/types.h>
#include <linux/quota.h>
#include <sys/syscall.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
/* #include "include/rquota.h" /**/
#include <sys/socket.h>
#include <netdb.h>

#include <strings.h>
#include <stdio.h>

#define Q_DIV / 2
#define Q_MUL * 2
#define CADR (caddr_t)

/* #define NO_RPC /**/
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

