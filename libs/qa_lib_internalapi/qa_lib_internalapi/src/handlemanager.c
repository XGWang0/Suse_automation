/*  handlemanager.c : managing functions for the handles used by libqainternal 
 *  Copyright ?
 *  Version 0.1 (2005-10-24) by <fseidel@suse.de>
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <unistd.h>
#include <libgen.h>
#include <assert.h>

#include "global.h"


/**
 *  Return the path to per-user storage base.
 * 
 *  @param storage_base_in c-string with dirname of storagebasedir
 *  @param storage_base_out point to char-array where a user-id modified version gets saved
 *  @return true if it worked, false otherwise
 */
bool myStorageBase(char *storage_base_in, char *storage_base_out)
{
	bool tmp_result=false;

	/*trivial pointer checks*/
	assert(storage_base_in);
	assert(storage_base_out);

	if (strlen(storage_base_in) > 0) {
		/*test if this is already a per user-dir*/
		if (strstr(storage_base_in,"_user") == NULL) {
			if (sprintf(storage_base_out,"%s_user%d",storage_base_in,(int) getuid()) > 0) {
				tmp_result=true;
			} else {
				fprintf(stderr,"libqainternal:%s(%s:%d):string could not be created\n",__func__,__FILE__,__LINE__);
			}
		} else {
			/*we already have a per-user-dir*/
			strcpy(storage_base_out,storage_base_in);
			tmp_result=true;
		}
	} else {
		fprintf(stderr,"libqainternal:%s(%s:%d):provided string for storage_basedir was empty\n",__func__,__FILE__,__LINE__);
	}

	return(tmp_result);
}


/**
 * Init the handle manager.
 * This function will create a new storage base unless we already have one.
 * In case the storage base already exists (or is not accessible due to
 * various reasons) the initialization fails.
 *
 * The storage base exists on per-user basis (e.i. each user has its own
 * storage_base).
 *
 * @param storage_base directory where to store internal files
 * @returns true if it worked
 */
bool init_handlemanager(char *storage_base)
{
	bool tmp_result=true;
	struct stat fileattrib;
	char lockfile[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
    int fd;

	/*trivial pointer check*/
	assert(storage_base);
	
	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);
	
	/*check we have our dir in place*/
	if (stat(myStorage,&fileattrib) == -1) {
		
		/*basedir is not there.. so we try to create it*/

		if (mkdir(myStorage,0777) == -1) {
			fprintf(stderr,"ERROR:libqainternal: could not create dir %s\n",myStorage);
			tmp_result=false;
		}
		
	} else {

		/*something with this name is there..
		lets see if its a directory we can access*/

		if (fileattrib.st_mode & S_IFDIR) {
		
			/*yes,its a direcotry at least...*/
			if (access(myStorage, R_OK | W_OK)) {
				/*...and we have read and write access*/
			} else {
				tmp_result=false;
			}

		} else {

			/*NO, its no directory :(  ... panic! */
			fprintf(stderr,"ERROR:libqainternal: %s is no file and so cannot be used as basedir for interals\n",myStorage);
			tmp_result=false;
		}
	}



	/*only go on if the previous checks were ok*/
	/*we now can be sure that there is a dir we can write in*/
	if (tmp_result) {
		
		/*look for a previous lockfile*/
        snprintf(lockfile,MAXFILENAMELEN,"%s/%s", myStorage, LOCKFILE_NAME);
		if (stat(lockfile,&fileattrib) == 0) {
			fprintf(stderr,"ERROR:libqainternal: old lockfile %s was found\n",lockfile);
			tmp_result=false;
		} else {
			/*create ready-state file*/
            snprintf(lockfile,MAXFILENAMELEN,
                     "%s/%s", myStorage, STORAGEREADY_NAME);
            fd = creat(lockfile, 0666);
            if (fd == -1) {
                perror("Unable to create lockfile");
                assert(fd != -1);
            }
			assert(close(fd) == 0);		
		}
	}

	return(tmp_result);
}

/**
 *  Check if the storage is initialized.
 *
 *  @param storage_base c-string with directory of qainternal storage
 *  @returns true if inited with ready-file, otherwise false
 */
bool is_storageready(char *storage_base)
{
	bool tmp_result;
	char readyfile[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
	struct stat tmp;
//    printf("DEBUG: entering is_storageready\n");

	/*trivial pointer check*/
	assert(storage_base);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);

	/*put together read-filename*/
    snprintf(readyfile,MAXFILENAMELEN,
             "%s/%s", myStorage, STORAGEREADY_NAME);

	/*check for file*/
	if (stat(readyfile,&tmp) == -1) {
		tmp_result=false;
	} else {
		tmp_result=true;
	}

	return(tmp_result);
}

/**
 *  Check if the handle storage is locked.
 *
 *  @param storage_base c-string with directory of qainternal storage
 *  @return true if the storagebase is locked, otherwise false
 */
bool is_storagelocked(char *storage_base)
{
	bool tmp_result;
	char lockfile[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
	struct stat tmp;

	/*trivial pointer check*/
	assert(storage_base);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);

    snprintf(lockfile,MAXFILENAMELEN,
             "%s/%s", myStorage, LOCKFILE_NAME);

	if (stat(lockfile,&tmp) == -1) {
		tmp_result=false;
	} else {
		tmp_result=true;
	}
	
	return(tmp_result);
}

/**
 *  Lock the handle storage.
 *
 *  @param storage_base c-string with directory of qainternal storage
 *  @return true if locking was successful, otherwise false
 */
bool lock_storage(char *storage_base)
{
	bool tmp_result=false;
	char lockfile[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
    int fd;

	/*trivial pointer check*/
	assert(storage_base);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);

	if (is_storageready(myStorage)) {
        snprintf(lockfile,MAXFILENAMELEN,
             "%s/%s", myStorage, LOCKFILE_NAME);
        
        fd = creat(lockfile, 0666);
        if (fd == -1) {
            perror("Unable to create lockfile");
        }
		if (close(fd) == 0) {
			tmp_result=true;
		} else {
			perror("libqainternal:lock_storage");
		}
		
	} else {
		fprintf(stderr,"ERROR:libqainternal:lock_storage: %s is not ready\n",myStorage);
	}

	return(tmp_result);
}


/**
 *  Unlock the handle storage.
 *
 *  @param storage_base: c-string with directory of qainternal storage
 *  @return true if unlocking was successful, otherwise false
 */
bool unlock_storage(char *storage_base)
{
        bool tmp_result=false;
        char lockfile[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];

        /*trivial pointer check*/
        assert(storage_base);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);

        if (is_storageready(myStorage)) {
                snprintf(lockfile,MAXFILENAMELEN,
                         "%s/%s", myStorage, LOCKFILE_NAME);

                if ((remove(lockfile)) == 0) {
                        tmp_result=true;
                } else {
                        perror("libqainternal:unlock_storage");
                }

        } else {
                fprintf(stderr,"ERROR:libqainternal:handlemanager:unlock_storage: %s is not a ready internal storage\n",myStorage);
        }

        return(tmp_result);
}

/** Translate type of the handle to its prefix.
 *  @param type type of the handle
 *  @return prefix of the handle (e.g. FILEHANDLE_PREFIX)
 */
const char *get_handleprefix(char *type) {
    if (strcmp(type,"files") == 0)  {
        return FILEHANDLE_PREFIX; 
    } else 
    if (strcmp(type,"users") == 0) {
        return USERHANDLE_PREFIX; 
    } else
    if (strcmp(type,"configs") == 0) { 
        return CONFIGHANDLE_PREFIX; 
    } else
    if (strcmp(type,"services") == 0) {
        return SERVICEHANDLE_PREFIX; 
    } else
    if (strcmp(type,"commands") == 0) {
        return COMMANDHANDLE_PREFIX; 
    } else
    if (strcmp(type,"errors") == 0) {
        return ERRORHANDLE_PREFIX; 
    } else {
        return OTHERHANDLE_PREFIX; 
    }
}

/**
 *  @param storage_base c-string of the storage-basedir of libqainternal
 *  @param type c-string with the type of the handle (like "file")
 *  @param content c-string for the content of the hand (like filename, servicename etc.)
 *  @return true if handle could be created, false otherwise
 */
bool createHandle(char *storage_base,char *type, char *content, char *handle_out)
{
	bool tmp_result=true;
	char handlefile[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
	int tmp_int;
//    printf("DEBUG: entering createHandle\n");

	/*trivial pointer checks*/
	assert(storage_base);
	assert(type);
	assert(content);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);
    strcat(myStorage,"/");

	/*check if storage is ready*/
	if(! is_storageready(myStorage) && ! init_handlemanager(myStorage)) {
		tmp_result=false;
	} else {

        strncpy(handlefile,myStorage,MAXFILENAMELEN-1);
        strncat(handlefile,get_handleprefix(type), MAXFILENAMELEN-1);
//        printf("DEBUG: createHandle.handlefile: %s\n",handlefile);

        if ((tmp_int=mkstemp(handlefile)) == -1) {
            perror("libqainternal:createHandle");
            tmp_result=false;
            *handle_out = '\0';
        } else {
            assert(write(tmp_int,content,strlen(content)) > 0);
            assert(close(tmp_int) == 0);
            strcpy(handle_out,basename(handlefile));
//            printf("DEBUG: createHandle.handle_out: %s\n",handle_out);
			if (! lock_storage(myStorage)) tmp_result=false;

        }
	}
//    printf("DEBUG: createHandle.handle_out: %s\n",handle_out);
	return(tmp_result);
}


/*
 *  Param storage_base: c-string with path to libqainternal storage
 *  Param handle_in: c-string that has to contain a valid handle
 *  Param content_out: pointer to chararray with enough space for content that will be put in
 *  Returns: true on success, false otherwise
 */
bool resolveHandle(char *storage_base,char *handle_in,char *content_out)
{
	bool tmp_result=false;
	char filename[MAXFILENAMELEN];
	char buffer[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
	FILE *fp;

	/*trivial pointer check*/
	assert(storage_base);
	assert(handle_in);
	assert(content_out);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);

    snprintf(filename,MAXFILENAMELEN,"%s/%s",myStorage,handle_in);

	if ((fp=fopen(filename,"r")) != NULL) {
		assert(fgets(buffer,sizeof(buffer),fp) != NULL);

		strcpy(content_out,buffer);

		assert(fclose(fp) == 0);

		tmp_result=true;

	} else {
		perror("libqainternal:handlemanager:resolveHandle");
	}

	return(tmp_result);
}

/*
 *  Param storage_base: c-string with dir for libqainternal storage dir
 *  Param handle_in: c-string with the handle to clear/delete
 *  Returns: true on success, false otherwise
 */
bool deleteHandle(char *storage_base,char *handle_in)
{
	bool tmp_result=true;
	char filename[MAXFILENAMELEN];
	char myStorage[MAXFILENAMELEN];
	DIR *directory;
	struct dirent *dir_info;
	int counter=0;

	/*trivial pointer check*/
	assert(storage_base);
	assert(handle_in);

	/*redirect storage_base to a per user-dir*/
	myStorageBase(storage_base,myStorage);

	/*create filename to handle*/
    snprintf(filename,MAXFILENAMELEN,
             "%s/%s", myStorage, handle_in);

	if (remove(filename) == 0) {
		/*check if it was last handle and remove lock if so*/

		if ((directory=opendir(myStorage)) != NULL) {
			while ((dir_info=readdir(directory)) != NULL) {
				if (strcmp(dir_info->d_name,".") != 0 && 
					strcmp(dir_info->d_name,"..") != 0 &&
					strcmp(dir_info->d_name,LOCKFILE_NAME) != 0 &&
					strcmp(dir_info->d_name,STORAGEREADY_NAME) != 0) {
			
					counter++;
				}
			}

			closedir(directory);

			if (counter == 0) {
				/*yes, it was the last handle so lets unlock the storage*/

				unlock_storage(myStorage);	
			}		

		} else {
			perror("libqainternal:handlemanager:delteHandle");
			tmp_result=false;
		}
		
	} else {
		perror("libqainternal:handlemanager:deleteHandle");
		tmp_result=false;
	}

	return(tmp_result);
}

