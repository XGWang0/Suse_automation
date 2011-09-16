/*
 * libqainterl:global.h
 * Copyright ?
 * Description: lib-global defintions...
 */
#ifndef LIBQAINTERNAL_GLOBAL_H
#define LIBQAINTERNAL_GLOBAL_H
#include "libqainternal.h"

#define DFLTBUFFERSIZE 65536

#define INTERNAL_STORAGE_BASE "/tmp/qainternal"
#define LOCKFILE_NAME "lock.qainternal"
#define STORAGEREADY_NAME "ready.qainternal"

#define FILEHANDLE_PREFIX "QAFILEHDLXXXXXX"
#define SERVICEHANDLE_PREFIX "QASERVICEHDLXXXXXX"
#define ERRORHANDLE_PREFIX "QAERRHDLXXXXXX"
#define CONFIGHANDLE_PREFIX "QACONFIGHDLXXXXXX"
#define COMMANDHANDLE_PREFIX "QACMDHDLXXXXXX"
#define USERHANDLE_PREFIX "QAUSRHDLXXXXXX"
#define OTHERHANDLE_PREFIX "QAOTHHDLXXXXXX"


/*config-handling stuff*/
#define BACKUP_SUFFIX "_QAINTBACKUP"
#define CP_BIN "/bin/cp"
#define MV_BIN "/bin/mv"
#define RM_BIN "/bin/rm"



/*user-handling stuff*/
#define DFLTPASSWD "linux"
#define DFLTPASSWD_CRYPTED "QAofMIJLkd5Hc"
#define DFLTSALT "QA"
#define ID_BIN "/usr/bin/id"
#define USERADD_BIN "/usr/sbin/useradd"
#define USERDEL_BIN "/usr/sbin/userdel"
#define USERMOD_BIN "/usr/sbin/usermod"
#define GROUPMOD_BIN "/usr/sbin/groupmod"
#define PASSWD_BIN "/usr/bin/passwd"
#define PASSWD "/etc/passwd"

#endif
