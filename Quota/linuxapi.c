/*
**  Linux quotactl wrapper - support both quota API v1 and v2
*/

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "myconfig.h"

/* API v1 command definitions */
#define Q_V1_GETQUOTA  0x0300
#define Q_V1_SETQUOTA  0x0400
#define Q_V1_GETSTATS  0x0800
/* API v2 command definitions */
#define Q_V2_GETQUOTA  0x0D00
#define Q_V2_SETQUOTA  0x0E00
#define Q_V2_GETSTATS  0x1100


/*
** Copy of struct declarations in the v2 quota.h header file
** (with structure names changed to avoid conflicts with v2 headers).
** This is required to be able to compile with v1 kernel headers.
*/

struct dqstats_v2 {
  u_int32_t lookups;
  u_int32_t drops;
  u_int32_t reads;
  u_int32_t writes;
  u_int32_t cache_hits;
  u_int32_t allocated_dquots;
  u_int32_t free_dquots;
  u_int32_t syncs;
  u_int32_t version;
};


struct dqblk_v2 {
  unsigned int dqb_ihardlimit;
  unsigned int dqb_isoftlimit;
  unsigned int dqb_curinodes;
  unsigned int dqb_bhardlimit;
  unsigned int dqb_bsoftlimit;
  qsize_t dqb_curspace;
  __kernel_time_t dqb_btime;
  __kernel_time_t dqb_itime;
};


/* this variable holds the API version number.
** 0 if not initialized
** 3 if determination failed (ignored)
*/
static int linux_api = 0;


/*
**  Check kernel quota version
**  Taken from quota-tools 3.01 by Jan Kara <jack@suse.cz>
*/

#define QSTAT_FILE "/proc/fs/quota"
#define KERN_KNOWN_QUOTA_VERSION (6*10000 + 5*100 + 0)

#ifdef xxxxx
static void linuxquota_get_api( void )
{
  struct dqstats_v2 stats;

  if (quotactl(QCMD(Q_V2_GETSTATS, 0), NULL, 0, (void *)&stats) == 0)
  {
    if (stats.version == KERN_KNOWN_QUOTA_VERSION)
      linux_api = 2;
    else
      linux_api = 3;
  }
  else
  {
    if (errno == EINVAL || errno == EFAULT || errno == EPERM)
      linux_api = 1;
    else
      linux_api = 3;
  }
}
#endif

static void linuxquota_get_api( void )
{
#ifndef LINUX_API_VERSION
  struct dqstats_v2 stats;
  struct dqstats_v2 v2_stats;
  FILE *f;
  int ret = 0;
  struct stat st;

  linux_api = 0;

  if ((f = fopen(QSTAT_FILE, "r")))
  {
    if (fscanf(f, "Version %u", &stats.version) != 1)
    { /* failed to parse stats -> set error code */
      stats.version = KERN_KNOWN_QUOTA_VERSION + 1;
    }
    fclose(f);
  }
  else if (quotactl(QCMD(Q_V2_GETSTATS, 0), NULL, 0, (void *)&v2_stats) >= 0)
  {
    stats.version = v2_stats.version;
  }
  else
  {
    if (errno == ENOSYS || errno == ENOTSUP)
    { /* Quota not compiled? */
       linux_api = 3;
    }
    else if (errno == EINVAL || errno == EFAULT || errno == EPERM)
    { /* Old quota compiled? */
      /* RedHat 7.1 (2.4.2-2) newquota check 
       * Q_V2_GETSTATS in it's old place, Q_GETQUOTA in the new place
       * (they haven't moved Q_GETSTATS to its new value) */
      int err_stat = 0;
      int err_quota = 0;
      char tmp[1024];

      if (quotactl(QCMD(Q_V1_GETSTATS, 0), NULL, 0, tmp))
        err_stat = errno;
      if (quotactl(QCMD(Q_V1_GETQUOTA, 0), "/dev/null", 0, tmp))
        err_quota = errno;

      /* On a RedHat 2.4.2-2 	we expect 0, EINVAL
       * On a 2.4.x 		we expect 0, ENOENT
       * On a 2.4.x-ac	we wont get here */
      if (err_stat == 0 && err_quota == EINVAL)
        linux_api = 2;
      else
        linux_api = 1;
    }
    else
      linux_api = 3;
  }

  if (linux_api == 0)
  {
    /* We might do some more generic checks in future but this should be enough for now */
    if (stats.version > KERN_KNOWN_QUOTA_VERSION)
    { /* Newer kernel than we know */
      linux_api = 3;
    }
    else if (stats.version <= 6*10000+4*100+0)
    { /* Old quota format */
      linux_api = 1;
    }
    else
    { /* new format */
      linux_api = 2;
    }
  }
#else /* defined LINUX_API_VERSION */
  linux_api = LINUX_API_VERSION;
#endif
}


/*
** Wrapper for the quotactl(GETQUOTA) call.
** For API v2 the results are copied back into a v1 structure.
*/
int linuxquota_query( const char * dev, int uid, int isgrp, struct dqblk * dqb )
{
  struct dqblk_v2 dqb2;
  int ret;

  if (linux_api == 0)
    linuxquota_get_api();

  if (linux_api == 2)
  {
    ret = quotactl(QCMD(Q_V2_GETQUOTA, (isgrp ? GRPQUOTA : USRQUOTA)), dev, uid, (caddr_t) &dqb2);
    if (ret == 0)
    {
      dqb->dqb_bhardlimit = dqb2.dqb_bhardlimit;
      dqb->dqb_bsoftlimit = dqb2.dqb_bsoftlimit;
      dqb->dqb_curblocks  = dqb2.dqb_curspace / DEV_QBSIZE;
      dqb->dqb_ihardlimit = dqb2.dqb_ihardlimit;
      dqb->dqb_isoftlimit = dqb2.dqb_isoftlimit;
      dqb->dqb_curinodes  = dqb2.dqb_curinodes;
      dqb->dqb_btime      = dqb2.dqb_btime;
      dqb->dqb_itime      = dqb2.dqb_itime;
    }
  }
  else /* if (linux_api = 1) */
  {
    ret = quotactl(QCMD(Q_V1_GETQUOTA, (isgrp ? GRPQUOTA : USRQUOTA)), dev, uid, (caddr_t) dqb);
  }
  return ret;
}

/*
** Wrapper for the quotactl(GETQUOTA) call.
** For API v2 the parameters are copied into a v2 structure.
*/
int linuxquota_setqlim( const char * dev, int uid, int isgrp, struct dqblk * dqb )
{
  struct dqblk_v2 dqb2;
  int ret;

  if (linux_api == 0)
    linuxquota_get_api();

  if (linux_api == 2)
  {
    dqb2.dqb_bhardlimit = dqb->dqb_bhardlimit;
    dqb2.dqb_bsoftlimit = dqb->dqb_bsoftlimit;
    dqb2.dqb_curspace   = 0;
    dqb2.dqb_ihardlimit = dqb->dqb_ihardlimit;
    dqb2.dqb_isoftlimit = dqb->dqb_isoftlimit;
    dqb2.dqb_curinodes  = 0;
    dqb2.dqb_btime      = dqb->dqb_btime;
    dqb2.dqb_itime      = dqb->dqb_itime;

    ret = quotactl (QCMD(Q_SETQLIM, (isgrp ? GRPQUOTA : USRQUOTA)), dev, uid, (caddr_t) &dqb2);
  }
  else /* if (linux_api = 1) */
  {
    dqb->QS_BCUR  = 0;
    dqb->QS_FCUR  = 0;
    ret = quotactl (QCMD(Q_SETQLIM, (isgrp ? GRPQUOTA : USRQUOTA)), dev, uid, (caddr_t) dqb);
  }

  return ret;
}

#if 0
main()
{
  linuxquota_get_api();
  printf("API=%d\n", linux_api);
}
#endif

