
/*
 *   Configuration for Solaris 5.4,5.5  (untested)
 *
 *   I couldn't check this.
 *   I don't even find a working cc on this f*cking OS
 */

#include <sys/param.h>
#include <sys/fs/quota.h>
#include <sys/mnttab.h>

#include <rpc/rpc.h>
#include <rpc/pmap_prot.h>
#include <rpcsvc/rquota.h>
#include <sys/socket.h>
#include <netdb.h>

#include <stdio.h>

#define Q_DIV
#define Q_MUL
#define CADR (caddr_t)

/* Not implemented yet.
   I guess you just have to open the file yourself. See man 3 getmntent
   Send me the diffs */
#define NO_OPEN_MNTTAB

