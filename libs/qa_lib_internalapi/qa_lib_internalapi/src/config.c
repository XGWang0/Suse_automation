/* libqainternal: config.c
 * Copyright ?
 * The config-handling functions of libqainternal
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <ctype.h>
#include <sys/vfs.h>
#include <assert.h>
#include <libgen.h>
#include <dirent.h>
#include <sys/stat.h>
#include <errno.h>

#include "global.h"
#include "error.h"

#include "libqainternal.h"

/*
 * ------------- config functions ----------------------
 */


/**
 *  Copy a configuration file to a given location.
 *
 *  This function copies a test config file and returns a handle of the
 *  copied file (handle to its new location). It preserves mode, ownership
 *  and timestamps. It also creates a backup of the original file
 *  (removeConfig will use this backup to restore the original config file).
 *
 *  In case the backup copy already exists the function will fail.
 *
 *  NOTE: copyConfig and removeConfig must be executed in the same process (the
 *  same pid). Otherwise the removeConfig fucntion will be unable to restore
 *  the backup.
 *
 *
 *  @param confighandle_out will be used to give back the handle (c-string)
 *  @param testconffilename_in has to contain a c-string with the config-file to use for test
 *  @param origconffilename_in has to contain a c-string with the original config-file to replace
 *  @return true if got successfully replaced, false otherwise
 */
bool copyConfig(char *confighandle_out, char *testconffilename_in, char *origconffilename_in)
{
        bool tmp_result=false;
        char backup[MAXFILENAMELEN];
        char command[DFLTBUFFERSIZE];
        struct stat buf;
        int n;

        /*trivial pointer checks*/
        assert(confighandle_out);
        assert(testconffilename_in);
        assert(origconffilename_in);

        /* get rid of the trailing '/' */
        n = strlen(origconffilename_in)-1;
        while ((n > 0) && (origconffilename_in[n] == '/')) {
            origconffilename_in[n] = '\0';
            n--;
        }
        
        /*create backup-filename*/
        snprintf(backup,MAXFILENAMELEN,"%s%s.%ld",origconffilename_in, BACKUP_SUFFIX,(long) getpid());


        if (stat(origconffilename_in,&buf) != 0) {
            perror("Unable to stat the config file");        
            return tmp_result;
        }

        /*if the config file is a directory then we want to backup/copy the
         * the whole content. Otherwise just the single file is
         * copied/back-uped */
        if (S_ISDIR(buf.st_mode)) {

            /*create copy-command ... to be replaced later on with c-only copying*/
            snprintf( command,DFLTBUFFERSIZE,"%s -f %s %s",
                      MV_BIN,origconffilename_in,backup
                    );

            if (WEXITSTATUS(system(command)) == 0) {
                if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                    if (createHandle(INTERNAL_STORAGE_BASE,"configs",origconffilename_in, confighandle_out)) {

                        /*replace the orig with test testconf*/
                        snprintf( command,DFLTBUFFERSIZE,"%s -pr %s %s",
                                  CP_BIN,testconffilename_in,origconffilename_in
                                );

                        if (WEXITSTATUS(system(command)) == 0) {
                            tmp_result = true;
                        } else {
                            removeConfig(confighandle_out);
                            *confighandle_out='\0';
                        }
                    }
                }
            } else {
                PRINTQAERROR("error while copying the orig conffile");
            }
        } else {

            /*create copy-command ... to be replaced later on with c-only copying*/
            snprintf( command,DFLTBUFFERSIZE,"%s -p %s %s",
                      CP_BIN,origconffilename_in,backup
                    );

            if (WEXITSTATUS(system(command)) == 0) {
                if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                    if (createHandle(INTERNAL_STORAGE_BASE,"configs",origconffilename_in, confighandle_out)) {

                        /*replace the orig with test testconf*/
                        snprintf( command,DFLTBUFFERSIZE,"%s %s %s",
                                  CP_BIN,testconffilename_in,origconffilename_in
                                );

                        if (WEXITSTATUS(system(command)) == 0) {
                            tmp_result=true;
                        } else {
                            removeConfig(confighandle_out);
                            *confighandle_out='\0';
                        }
                    }
                }

            } else {
                PRINTQAERROR("error while copying the orig conffile");
            }
        }
        return(tmp_result);
}



/**
 *  Remove the configuration file and restore the original one from backup.
 *  This function preserves mode, ownership and timestamps.
 *  @param confighandle_in (c-string) holding the config-handle
 *  @return true if got successfully restored previous state, false otherwise
 */
bool removeConfig(char *confighandle_in)
{
    bool tmp_result=false;
    char origconf[MAXFILENAMELEN];
    char backup[MAXFILENAMELEN];
    char command[DFLTBUFFERSIZE];
    struct stat buf;
    int n;

    /*trivial pointer checks*/
    assert(confighandle_in);

    if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
        if (resolveHandle(INTERNAL_STORAGE_BASE,confighandle_in,origconf)) {

            /* get rid of the trailing '/' */
            n = strlen(origconf)-1;
            while ((n > 0) && (origconf[n] == '/')) {
                origconf[n] = '\0';
                n--;
            }
 

            /*create backup-filename*/
            snprintf(backup,MAXFILENAMELEN,"%s%s.%ld",origconf, BACKUP_SUFFIX,(long) getpid());

            if (stat(origconf,&buf) != 0) {
                perror("Unable to stat the config file");        
                return tmp_result;
            }


            /* if the original config is a directory then we must take a
             * special care to copy all its content */
            if (S_ISDIR(buf.st_mode)) {
                /* delete the test config */
                snprintf( command, DFLTBUFFERSIZE, 
                          "%s -rf %s",RM_BIN, origconf
                        );

                if (WEXITSTATUS(system(command)) != 0) {
                    PRINTQAERROR("error while restoring backup");
                }


                /*replace the orig with test testconf*/
                snprintf( command, DFLTBUFFERSIZE, 
                          "%s %s %s",MV_BIN,backup,origconf
                        );

                if (WEXITSTATUS(system(command)) == 0) {
                        tmp_result=true;
                } else {
                        PRINTQAERROR("error while restoring backup");
                }

            } else {

                /*replace the orig with test testconf*/
                snprintf( command, DFLTBUFFERSIZE, 
                          "%s %s %s",MV_BIN,backup,origconf
                        );

                if (WEXITSTATUS(system(command)) == 0) {
                        remove(backup);
                        tmp_result=true;
                } else {
                        PRINTQAERROR("error while restoring backup");
                }
            }
        }

    } else {
        PRINTQAERROR("error while accessing the handle");
    }

    return(tmp_result);
}

/**
 *  Translate handle to a filename.
 *
 *  @param confighandle_in (c-string) holding the config-handle
 *  @param origconffilename_out pointer to char-array where to put the orig-conffilename
 *  @return true if got successfully resolved, false otherwise
 */
bool checkConfig(char *confighandle_in, char *origconffilename_out)
{
        bool tmp_result=false;
        char buffer[MAXFILENAMELEN];

        /*trivial pointer checks*/
        assert(confighandle_in);
        assert(origconffilename_out);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
               if (resolveHandle(INTERNAL_STORAGE_BASE,confighandle_in,buffer)) {

                        strcpy(origconffilename_out,buffer);
                        tmp_result=true;

                }
        } else {
                PRINTQAERROR("error while accessing the handle");
        }

        return(tmp_result);
}
