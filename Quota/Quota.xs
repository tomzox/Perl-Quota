#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "config.h"

#if !defined(HAS_BCOPY) || !defined(HAS_SAFE_BCOPY)
#define BCOPY my_bcopy
#else
#define BCOPY bcopy
#endif

#ifndef NO_MNTENT
FILE *mtab = NULL;
#else
struct statfs *mntp, *mtab = NULL;
int mtab_size = 0;
#endif

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
  switch (gq_rslt.GQR_STATUS) {
  case Q_OK:
    {
      struct timeval tv;

      gettimeofday(&tv, NULL);
      dqp->QS_BHARD =
	  gq_rslt.GQR_RQUOTA.rq_bhardlimit *
	  gq_rslt.GQR_RQUOTA.rq_bsize / DEV_BSIZE;
      dqp->QS_BSOFT =
	  gq_rslt.GQR_RQUOTA.rq_bsoftlimit *
	  gq_rslt.GQR_RQUOTA.rq_bsize / DEV_BSIZE;
      dqp->QS_BCUR =
	  gq_rslt.GQR_RQUOTA.rq_curblocks *
	  gq_rslt.GQR_RQUOTA.rq_bsize / DEV_BSIZE;
      dqp->QS_FHARD = gq_rslt.GQR_RQUOTA.rq_fhardlimit;
      dqp->QS_FSOFT = gq_rslt.GQR_RQUOTA.rq_fsoftlimit;
      dqp->QS_FCUR = gq_rslt.GQR_RQUOTA.rq_curfiles;
      dqp->QS_BTIME =
	  tv.tv_sec + gq_rslt.GQR_RQUOTA.rq_btimeleft;
      dqp->QS_FTIME =
	  tv.tv_sec + gq_rslt.GQR_RQUOTA.rq_ftimeleft;

      if(dqp->QS_BHARD==0 && dqp->QS_BSOFT==0 &&
         dqp->QS_FHARD==0 && dqp->QS_FSOFT==0) {
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
  BCOPY((char *)hp->h_addr, (char *)&remaddr.sin_addr, hp->h_length);
  remaddr.sin_family = AF_INET;
  remaddr.sin_port = 0;

  /*
   *  Create client RPC handle
   */
  if ((client = (CLIENT *)clntudp_create(&remaddr, prognum,
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
  return (xdr_string(xdrs, &gqp->gqa_pathp, 1024) &&
          xdr_int(xdrs, &gqp->gqa_uid));
}

bool_t
xdr_getquota_rslt(xdrs, gqp)
XDR *xdrs;
struct getquota_rslt *gqp;
{
  return (xdr_union(xdrs,
    (int *) &gqp->GQR_STATUS, (char *) &gqp->GQR_RQUOTA,
    gq_des, (xdrproc_t) xdr_void));
}

bool_t
xdr_rquota(xdrs, rqp)
XDR *xdrs;
struct rquota *rqp;
{
  return (xdr_int(xdrs, &rqp->rq_bsize) &&
      xdr_bool(xdrs, &rqp->rq_active) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_bhardlimit) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_bsoftlimit) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_curblocks) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_fhardlimit) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_fsoftlimit) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_curfiles) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_btimeleft) &&
      xdr_u_long(xdrs, (unsigned long *)&rqp->rq_ftimeleft) );
}
#endif
#endif

/* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 *
 *  The Perl interface
 *
 */

MODULE = Quota  PACKAGE = Quota
PROTOTYPES: DISABLE

void
query(dev,uid=getuid())
	char *	dev
	int	uid
	PPCODE:
	{
	  struct dqblk dqblk;
	  char *p = NULL;
	  int err;
#ifdef USE_IOCTL
	  struct quotactl qp;
	  int fd = -1;
#endif

	  if((*dev != '/') && (p = strchr(dev, ':'))) {
#ifndef NO_RPC
	    *p = '\0';
	    err = getnfsquota(dev, p+1, uid, &dqblk);
	    *p = ':';
#else
            errno = ENOSYS;
#endif
	  }
	  else {
#ifdef USE_IOCTL
	    qp.op = Q_GETQUOTA;
	    qp.uid = uid;
	    qp.addr = (char *)&dqblk;
	    err = (((fd = open(dev, O_RDONLY)) == -1) ||
	           (ioctl(fd, Q_QUOTACTL, &qp) == -1));
#else
#ifndef Q_CTL_V2
	    err = quotactl(Q_GETQUOTA, dev, uid, CADR &dqblk);
#else
	    err = quotactl(dev, QCMD(Q_GETQUOTA, USRQUOTA), uid, CADR &dqblk);
#endif
#endif
          }
	  if(!err) {
	    EXTEND(sp, 8);
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BCUR  Q_DIV)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BSOFT Q_DIV)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BHARD Q_DIV)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BTIME)));

	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FCUR)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FSOFT)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FHARD)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FTIME)));
	  }
#ifdef USE_IOCTL
	  if(fd != -1) close(fd);
#endif
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
#ifdef USE_IOCTL
	  struct quotactl qp;
	  int fd;

	  qp.op = Q_SETQLIM;
	  qp.uid = uid;
	  qp.addr = (char *)&dqblk;
#endif
	  if(timelimflag != 0) timelimflag = 1;
	  dqblk.QS_BSOFT = bs Q_MUL;
	  dqblk.QS_BHARD = bh Q_MUL;
	  dqblk.QS_BTIME = timelimflag;
	  dqblk.QS_FSOFT = fs;
	  dqblk.QS_FHARD = fh;
	  dqblk.QS_FTIME = timelimflag;
#ifdef USE_IOCTL
	  if((fd = open(dev, O_RDONLY)) != -1) {
	    RETVAL = (ioctl(fd, Q_QUOTACTL, &qp) != 0);
	    close(fd);
	  }
	  else
	    RETVAL = -1;
#else
#ifndef Q_CTL_V2
	  RETVAL = quotactl (Q_SETQLIM, dev, uid, CADR &dqblk);
#else
	  RETVAL = quotactl (dev, QCMD(Q_SETQUOTA,USRQUOTA), uid, CADR &dqblk);
#endif
#endif
	}
	OUTPUT:
	RETVAL

int
sync(dev=NULL)
	char *	dev
	CODE:
#ifdef USE_IOCTL
	{
	  struct quotactl qp;
	  int fd;

	  if(dev == NULL) {
	    qp.op = Q_ALLSYNC;
	    dev = "/";   /* is probably ignored anyways */
	  }
	  else
	    qp.op = Q_SYNC;
	  if((fd = open(dev, O_RDONLY)) != -1) {
	    RETVAL = (ioctl(fd, Q_QUOTACTL, &qp) != 0);
	    if(errno == ESRCH) errno = EINVAL;
	    close(fd);
	  }
	  else
	    RETVAL = -1;
	}
#else
#ifndef Q_CTL_V2
	RETVAL = quotactl(Q_SYNC, dev, 0, NULL);
#else
	if(dev == NULL) dev = "/";
	RETVAL = quotactl(dev, QCMD(Q_SYNC, USRQUOTA), 0, NULL);
#endif
#endif
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
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BCUR  Q_DIV)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BSOFT Q_DIV)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BHARD Q_DIV)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_BTIME)));

	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FCUR)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FSOFT)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FHARD)));
	    PUSHs(sv_2mortal(newSViv(dqblk.QS_FTIME)));
	  }
#else
	  errno = ENOSYS;
#endif
	}

int
setmntent()
	CODE:
	{
#ifndef NO_MNTENT
#ifndef NO_OPEN_MNTTAB
	  if(mtab != NULL) endmntent(mtab);
	  if((mtab = setmntent(MOUNTED, "r")) == NULL)
#else
	  if(mtab != NULL) fclose(mtab);
	  if((mtab = fopen(MOUNTED,"r")) == NULL)
#endif
	    RETVAL = -1;
	  else
	    RETVAL = 0;
#else
	  /* if(mtab != NULL) free(mtab); */
	  if((mtab_size = getmntinfo(&mtab, MNT_NOWAIT)) <= 0)
	    RETVAL = -1;
	  else
	    RETVAL = 0;
	  mntp = mtab;
#endif
	}
	OUTPUT:
	RETVAL

void
getmntent()
	PPCODE:
	{
#ifndef NO_MNTENT
#ifndef NO_OPEN_MNTTAB
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
#else
	  struct mnttab mntp;
	  if(mtab != NULL) {
	    if(getmntent(mtab, &mntp) == 0)  {
	      EXTEND(sp, 4);
	      PUSHs(sv_2mortal(newSVpv(mntp.mnt_special, strlen(mntp.mnt_special))));
	      PUSHs(sv_2mortal(newSVpv(mntp.mnt_mountp, strlen(mntp.mnt_mountp))));
	      PUSHs(sv_2mortal(newSVpv(mntp.mnt_fstype, strlen(mntp.mnt_fstype))));
	      PUSHs(sv_2mortal(newSVpv(mntp.mnt_mntopts, strlen(mntp.mnt_mntopts))));
	    }
	  }
	  else
	    errno = EBADF;
#endif
#else
	  if((mtab != NULL) && mtab_size) {
	    EXTEND(sp,4);
	    PUSHs(sv_2mortal(newSVpv(mntp->f_mntfromname, strlen(mntp->f_mntfromname))));
	    PUSHs(sv_2mortal(newSVpv(mntp->f_mntonname, strlen(mntp->f_mntonname))));
	    PUSHs(sv_2mortal(newSViv((IV)mntp->f_type)));
	    PUSHs(sv_2mortal(newSViv((IV)mntp->f_flags)));
	    mtab_size--;
	    mntp++;
	  }
#endif
	}

void
endmntent()
	PPCODE:
	{
	  if(mtab != NULL) {
#ifndef NO_MNTENT
#ifndef NO_OPEN_MNTTAB
	    endmntent(mtab);   /* returns always 1 in SunOS */
#else
	    fclose(mtab);
#endif
#else
	    /* if(mtab != NULL) free(mtab); */
	    mtab = NULL;
#endif
	  }
	}

char *
getqcargtype()
	CODE:
#ifdef USE_IOCTL
	RETVAL = "mntpt";
#else
#ifdef Q_CTL_V2
	RETVAL = "path";
#else
	RETVAL = "dev";
#endif
#endif
	OUTPUT:
	RETVAL

