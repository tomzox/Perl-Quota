#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "config.h"

FILE *mtab;

/*
 * fetch quotas from remote host
 */

#ifndef NO_RPC
int
getnfsquota(hostp, fsnamep, uid, dqp)
  char *hostp, *fsnamep;
  int uid;
  struct dqblk *dqp;
{
  struct getquota_args gq_args;
  struct getquota_rslt gq_rslt;

  gq_args.gqa_pathp = fsnamep;
  gq_args.gqa_uid = uid;
  if (callaurpc(hostp, RQUOTAPROG, RQUOTAVERS, RQUOTAPROC_GETQUOTA,
      xdr_getquota_args, &gq_args, xdr_getquota_rslt, &gq_rslt) != 0) {
    return (-1);
  }
  switch (gq_rslt.gqr_status) {
  case Q_OK:
    {
      struct timeval tv;

      gettimeofday(&tv, NULL);
      dqp->dqb_bhardlimit =
	  gq_rslt.gqr_rquota.rq_bhardlimit *
	  gq_rslt.gqr_rquota.rq_bsize / DEV_BSIZE;
      dqp->dqb_bsoftlimit =
	  gq_rslt.gqr_rquota.rq_bsoftlimit *
	  gq_rslt.gqr_rquota.rq_bsize / DEV_BSIZE;
      dqp->dqb_curblocks =
	  gq_rslt.gqr_rquota.rq_curblocks *
	  gq_rslt.gqr_rquota.rq_bsize / DEV_BSIZE;
      dqp->dqb_fhardlimit = gq_rslt.gqr_rquota.rq_fhardlimit;
      dqp->dqb_fsoftlimit = gq_rslt.gqr_rquota.rq_fsoftlimit;
      dqp->dqb_curfiles = gq_rslt.gqr_rquota.rq_curfiles;
      dqp->dqb_btimelimit =
	  tv.tv_sec + gq_rslt.gqr_rquota.rq_btimeleft;
      dqp->dqb_ftimelimit =
	  tv.tv_sec + gq_rslt.gqr_rquota.rq_ftimeleft;

      if(dqp->dqb_bhardlimit==0 && dqp->dqb_bsoftlimit==0 &&
         dqp->dqb_fhardlimit==0 && dqp->dqb_fsoftlimit==0) {
        errno = ESRCH;
	return(-1);
      }
      return (0);
    }

  case Q_NOQUOTA:
    errno = ESRCH;
    break;

  case Q_EPERM:
    errno = EPERM;
    break;

  default:
    errno = EINVAL;
    break;
  }
  return (-1);
}

callaurpc(host, prognum, versnum, procnum, inproc, in, outproc, out)
  char *host;
  xdrproc_t inproc, outproc;
  char *in, *out;
{
  struct sockaddr_in remaddr;
  struct hostent *hp;
  enum clnt_stat clnt_stat;
  struct timeval rep_time, timeout;
  CLIENT *client = NULL;
  int socket = RPC_ANYSOCK;

  /*
   *  Get IP address, port is determined via the remote portmap daemon
   */
  if ((hp = gethostbyname(host)) == NULL) return ((int) RPC_UNKNOWNHOST);
  rep_time.tv_sec = 4;
  rep_time.tv_usec = 0;
  bcopy(hp->h_addr, &remaddr.sin_addr, hp->h_length);
  remaddr.sin_family = AF_INET;
  remaddr.sin_port = 0;

  /*
   *  Create client RPC handle
   */
  if ((client = clntudp_create(&remaddr, prognum,
      versnum, rep_time, &socket)) == NULL) {
	  return ((int) rpc_createerr.cf_stat);
  }
  client->cl_auth = authunix_create_default();

  /*
   *  Call remote server
   */
  timeout.tv_sec = 12;
  timeout.tv_usec = 0;
  clnt_stat = clnt_call(client, procnum,
                        inproc, in, outproc, out, timeout);
  if (client) clnt_destroy(client);

  return ((int) clnt_stat);
}

#ifdef MY_XDR

struct xdr_discrim gq_des[2] = {
  { (int)Q_OK, xdr_rquota },
  { 0, NULL }
};

bool_t
xdr_getquota_args(xdrs, gqp)
XDR *xdrs;
struct getquota_args *gqp;
{
  return (xdr_path(xdrs, &gqp->gqa_pathp) &&
          xdr_int(xdrs, &gqp->gqa_uid));
}

bool_t
xdr_getquota_rslt(xdrs, gqp)
XDR *xdrs;
struct getquota_rslt *gqp;
{
  return (xdr_union(xdrs,
    (int *) &gqp->gqr_status, (char *) &gqp->gqr_rquota,
    gq_des, (xdrproc_t) xdr_void));
}

bool_t
xdr_rquota(xdrs, rqp)
XDR *xdrs;
struct rquota *rqp;
{
  return (xdr_int(xdrs, &rqp->rq_bsize) &&
      xdr_bool(xdrs, &rqp->rq_active) &&
      xdr_u_long(xdrs, &rqp->rq_bhardlimit) &&
      xdr_u_long(xdrs, &rqp->rq_bsoftlimit) &&
      xdr_u_long(xdrs, &rqp->rq_curblocks) &&
      xdr_u_long(xdrs, &rqp->rq_fhardlimit) &&
      xdr_u_long(xdrs, &rqp->rq_fsoftlimit) &&
      xdr_u_long(xdrs, &rqp->rq_curfiles) &&
      xdr_u_long(xdrs, &rqp->rq_btimeleft) &&
      xdr_u_long(xdrs, &rqp->rq_ftimeleft) );
}
#endif
#endif

/* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 *
 *  The Perl interface
 *
 */

MODULE = Quota  PACKAGE = Quota

void
query(dev,uid=getuid())
	char *	dev
	int	uid
	PPCODE:
	{
	  struct dqblk dqblk;
	  if(!quotactl(Q_GETQUOTA, dev, uid, CADR &dqblk)) {
	    EXTEND(sp, 8);
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_curblocks  Q_DIV)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_bsoftlimit Q_DIV)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_bhardlimit Q_DIV)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_btimelimit)));

	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_curfiles)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_fsoftlimit)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_fhardlimit)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_ftimelimit)));
	  }
	}

int
setqlim(dev,uid,bs,bh,fs,fh,timelimflag=0)
	char *	dev
	int	uid
	int	bs
	int	bh
	int	fs
	int	fh
	int	timelimflag
	CODE:
	{
	  struct dqblk dqblk;
	  if(timelimflag != 0) timelimflag = 1;

	  dqblk.dqb_bsoftlimit = bs Q_MUL;
	  dqblk.dqb_bhardlimit = bh Q_MUL;
	  dqblk.dqb_btimelimit = timelimflag;
	  dqblk.dqb_fsoftlimit = fs;
	  dqblk.dqb_fhardlimit = fh;
	  dqblk.dqb_ftimelimit = timelimflag;
	  RETVAL = quotactl (Q_SETQLIM, dev, uid, CADR &dqblk);
	}
	OUTPUT:
	RETVAL

int
sync(dev=NULL)
	char *	dev
	CODE:
	RETVAL = quotactl (Q_SYNC, dev, 0, NULL);
	OUTPUT:
	RETVAL

void
rpcquery(host,path,uid=getuid())
	char *	host
	char *	path
	int	uid
	PPCODE:
	{
#ifndef NO_RPC
	  struct dqblk dqblk;
	  if(getnfsquota(host, path, uid, &dqblk) == 0) {
	    EXTEND(sp, 8);
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_curblocks  Q_DIV)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_bsoftlimit Q_DIV)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_bhardlimit Q_DIV)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_btimelimit)));

	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_curfiles)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_fsoftlimit)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_fhardlimit)));
	    PUSHs(sv_2mortal(newSVnv(dqblk.dqb_ftimelimit)));
	  }
#else
	  errno = ENOSYS;
#endif
	}

int
setmntent()
	CODE:
	{
	  if(mtab != NULL) endmntent(mtab);
	  if((mtab = setmntent(MOUNTED, "r")) == NULL)
	    RETVAL = -1;
	  else
	    RETVAL = 0;
	}
	OUTPUT:
	RETVAL

void
getmntent()
	PPCODE:
	{
	  struct mntent *mntp;
	  if(mtab != NULL) {
	    if(mntp = getmntent(mtab)) {
	      EXTEND(sp, 4);
	      PUSHs(sv_2mortal(newSVpv(mntp->mnt_fsname, strlen(mntp->mnt_fsname))));
	      PUSHs(sv_2mortal(newSVpv(mntp->mnt_dir, strlen(mntp->mnt_dir))));
	      PUSHs(sv_2mortal(newSVpv(mntp->mnt_type, strlen(mntp->mnt_type))));
	      PUSHs(sv_2mortal(newSVpv(mntp->mnt_opts, strlen(mntp->mnt_opts))));
	    }
	  }
	  else
	    errno = EBADF;
	}

void
endmntent()
	PPCODE:
	{
	  if(mtab != NULL) {
	    endmntent(mtab);   /* returns always 1 in SunOS */
	    mtab = NULL;
	  }
	}
