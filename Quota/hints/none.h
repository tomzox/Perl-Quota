
/*
 *   Configuration example for unknown OS
 */

#include <sys/param.h>

/* This is needed for the quotactl syscall. See man 2 quotactl */
#include <ufs/quota.h>

/* This is needed for the mntent library routines. See man 3 getmntent */
#include <mntent.h>

/* See man 3 callrpc and man 3 rquota */
#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>

/* See man 2 socket and man 3 gethostbyname */
#include <sys/socket.h>
#include <netdb.h>

/* Needed for definition of type FILE for mntent routines */
#include <stdio.h>

/* These values depend on the blocksize of your filesystem.
   Scale it the way, that quota values are in kB
   For SYSV systems you can set these defines to empty */
#define Q_DIV / 2
#define Q_MUL * 2

/* Some systems need to cast the dqblk structure
   Do change only if your compiler complains */
#define CADR (caddr_t)

/* define if you don't want the rpcquery functionality */
#define NO_RPC

/* define if you don't have a shared librpcsvc library
   this includes the needed xdr routines from within this module */
#define MY_RPC

