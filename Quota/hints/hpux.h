
/*
 *   Configuration for HP-UX 9.0.1
 */

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
#define CADR (caddr_t)

/*  My HP-UX has no shared librpcsvc. So I need to include the
 *  xdr routines supplied with this module
 */
#define MY_XDR

