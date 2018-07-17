/** libqainternal: cleanup.c
 * Copyright ?
 * The handle-cleanup functions of libqainternal
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/vfs.h>
#include <fcntl.h>
#include <dirent.h>
#include <assert.h>

#include "global.h"
#include "error.h"

#include "cleanup.h"

#include "libqainternal.h"
#include "handlemanager.h"

/*
 * ------------- cleanup functions ----------------------
 */

/**
 *  Cleanup function.
 *
 *  This function takes care of all temporary objects created by the API
 *  (such as files, users, services etc) and does the cleanup.
 *
 *  NOTE: this function takes no care about stuff created by functions like
 *  addUser or createTempFile. You have to take cleanup these files
 *  manually.
 *  
 *  @param handletype_in one of "files","users","configs","services","errors","all",""
 *  @return true if cleanup was successfull, false otherwise
 */
bool cleanup(char *handletype_in)
{
	bool tmp_result=false;
	DIR *dir;
	struct dirent *dir_info;
	char storage_base[MAXFILENAMELEN];
	char backup[MAXFILENAMELEN];
	char buffer[DFLTBUFFERSIZE];
	char command[DFLTBUFFERSIZE];
	int problem_counter=0;

	/*trivial pointer checks*/
	assert(handletype_in);

	if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {

		if (strcmp(handletype_in,"files") == 0) {
			/*cleanup filehandles*/		

            myStorageBase(INTERNAL_STORAGE_BASE,storage_base);
			if ((dir=opendir(storage_base)) != NULL) {

				while ((dir_info=readdir(dir)) != NULL) {
					if (strncmp(dir_info->d_name,FILEHANDLE_PREFIX,5) == 0) {
						/*yes, we found a filehandle... now delete it*/

						if (! deleteHandle(INTERNAL_STORAGE_BASE,dir_info->d_name)) {
							problem_counter++;
						}
                    }
                }				

                if (problem_counter == 0) {
                    tmp_result=true;
                } else {
                    fprintf(stderr,"WARNING:libqainternal:cleanup:files: could not delete %d filehandles\n",problem_counter);
                }

                assert(closedir(dir) == 0);
            } else {
                    PRINTQAERROR("files");
            }

        } else if (strcmp(handletype_in,"users") == 0) {
                /*cleanup userhandles*/

                myStorageBase(INTERNAL_STORAGE_BASE,storage_base);
                if ((dir=opendir(storage_base)) != NULL) {

                    while ((dir_info=readdir(dir)) != NULL) {
                        if (strncmp(dir_info->d_name,USERHANDLE_PREFIX,5) == 0) {
                            /*yes, we found a userhandle... now delete it*/

                            if (! deleteHandle(INTERNAL_STORAGE_BASE,dir_info->d_name)) {
                                problem_counter++;
                            }
                        }
                    }

                    if (problem_counter == 0) {
                        tmp_result=true;
                    } else {
                        fprintf(stderr,"WARNING:libqainternal:cleanup:users: could not delete %d filehandles\n",problem_counter);
                    }

                    assert(closedir(dir) == 0);
                } else {
                    PRINTQAERROR("users");
                }

        } else if (strcmp(handletype_in,"configs") == 0) {
                /*cleanup confighandles*/

                myStorageBase(INTERNAL_STORAGE_BASE,storage_base);
                if ((dir=opendir(storage_base)) != NULL) {

                        while ((dir_info=readdir(dir)) != NULL) {
                                if (strncmp(dir_info->d_name,CONFIGHANDLE_PREFIX,5) == 0) {
                                        /*yes, we found a confighandle... now delete it*/

                                        /*..but we try if a corresponding backup needs to be restored*/
                                        if (resolveHandle(storage_base,dir_info->d_name,buffer)) {
                                                snprintf( backup,MAXFILENAMELEN,
                                                                "%s%s ",
                                                                buffer,BACKUP_SUFFIX
                                                        );

                                                snprintf( command,DFLTBUFFERSIZE,
                                                                "%s -p %s %s &>/dev/null",
                                                                CP_BIN, backup, buffer
                                                        );

                                                system(command);
                                        }

                                        if (! deleteHandle(INTERNAL_STORAGE_BASE,dir_info->d_name)) {
                                                problem_counter++;
                                        }
                                }
                        }

                        if (problem_counter == 0) {
                                tmp_result=true;
                        } else {
                                fprintf(stderr,"WARNING:libqainternal:cleanup:configs: could not delete %d filehandles\n",problem_counter);
                        }

                        assert(closedir(dir) == 0);
                } else {
                        PRINTQAERROR("configs");
                }


        } else if (strcmp(handletype_in,"services") == 0) {
                /*cleanup servicehandles*/

                myStorageBase(INTERNAL_STORAGE_BASE,storage_base);
                if ((dir=opendir(storage_base)) != NULL) {

                        while ((dir_info=readdir(dir)) != NULL) {
                                if (strncmp(dir_info->d_name,SERVICEHANDLE_PREFIX,5) == 0) {
                                        /*yes, we found a servicehandle... now delete it*/

                                        if (! deleteHandle(INTERNAL_STORAGE_BASE,dir_info->d_name)) {
                                                problem_counter++;
                                        }
                                }
                        }

                        if (problem_counter == 0) {
                                tmp_result=true;
                        } else {
                                fprintf(stderr,"WARNING:libqainternal:cleanup:services: could not delete %d filehandles\n",problem_counter);
                        }

                        assert(closedir(dir) == 0);
                } else {
                        PRINTQAERROR("services");
                }


        } else if (strcmp(handletype_in,"errors") == 0) {
                /*cleanup errorhandles*/

                myStorageBase(INTERNAL_STORAGE_BASE,storage_base);
                if ((dir=opendir(storage_base)) != NULL) {

                        while ((dir_info=readdir(dir)) != NULL) {
                                if (strncmp(dir_info->d_name,ERRORHANDLE_PREFIX,5) == 0) {
                                        /*yes, we found a errorhandle... now delete it*/

                                        if (! deleteHandle(INTERNAL_STORAGE_BASE,dir_info->d_name)) {
                                                problem_counter++;
                                        }
                                }
                        }

                        if (problem_counter == 0) {
                                tmp_result=true;
                        } else {
                                fprintf(stderr,"WARNING:libqainternal:cleanup:errors: could not delete %d filehandles\n",problem_counter);
                        }

                        assert(closedir(dir) == 0);
                } else {
                        PRINTQAERROR("errors");
                }


        } else if (strcmp(handletype_in,"all") == 0) {
                /*cleanup all handles of any type*/

                /*first try the now know types that need special handling*/
                cleanup("files");
                cleanup("users");
                cleanup("configs");
                cleanup("services");
                cleanup("errors");

                /*now we do the rest if any*/
                myStorageBase(INTERNAL_STORAGE_BASE,storage_base);
                if ((dir=opendir(storage_base)) != NULL) {

                        while ((dir_info=readdir(dir)) != NULL) {
                                if (strncmp(dir_info->d_name,"QA",2) == 0) {
                                        /*yes, we found a handle... now delete it*/

                                        if (! deleteHandle(INTERNAL_STORAGE_BASE,dir_info->d_name)) {
                                                problem_counter++;
                                        }
                                }
                        }

                        if (problem_counter == 0) {
                                tmp_result=true;
                        } else {
                                fprintf(stderr,"WARNING:libqainternal:cleanup:all: could not delete %d filehandles\n",problem_counter);
                        }

                        assert(closedir(dir) == 0);
                } else {
                        PRINTQAERROR("all");
                }


        } else if (strlen(handletype_in) == 0) {
                /*hm, do nothing here by definition...*/

        } else {
                /*unknown handletype given :( */

                PRINTQAERROR("WARNING: the handletype is unknown");
        }


    }

    return(tmp_result);
}



