
/*
 *   Configuration for SunOS 4.1.3
 */

#include <sys/param.h>
#include <ufs/quota.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>

#define Q_DIV / 2
#define Q_MUL * 2
#define CADR

