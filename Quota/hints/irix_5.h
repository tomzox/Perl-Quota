
/*
 *   Configuration for IRIX 5.3
 */

#include <sys/param.h>
#include <sys/quota.h>
#include <mntent.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>

#define Q_DIV
#define Q_MUL
#define CADR (caddr_t)

