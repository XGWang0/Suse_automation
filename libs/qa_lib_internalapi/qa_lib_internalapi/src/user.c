/* libqainternal: user.c
 * Copyright ?
 * The user-handling functions of libqainternal
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

#include "global.h"
#include "error.h"

#include "user.h"

#include "libqainternal.h"

/*
 * ------------- userhandling functions ----------------------
 */

/**
 * Add user to a tested system.
 *
 * Simple adduser function which will create a user with home directory (in
 * /tmp/home to get rid of NFS-mounted homes) and a default password
 * DFLTPASSWD. You can specify main group of the user but this group must
 * exist before you call addUser. If you don't want to specify the main
 * group and use the default one just pass NULL as the group_in parameter.
 *
 *  @Param userhandle_out will be used to give back the handle (c-string)
 *  @Param username_in has to contain a c-string with the username to add
 *  @Param group_in name or number of the user's main group (NULL for
 *  default)
 *  @Return true if got successfully added and didn't exist before, false otherwise
 */
bool addUser(char *userhandle_out, char *username_in, char *group_in)
{
        bool tmp_result=false;
        char command[DFLTBUFFERSIZE];
        char main_group[DFLTBUFFERSIZE];
        int status;

        /*trivial pointer checks*/
        assert(userhandle_out);
        assert(username_in);

        if (group_in == NULL) {
            main_group[0] = '\0';
        } else {
            snprintf(main_group, DFLTBUFFERSIZE, "-g %s",group_in);
        }

        /*create command to add user*/
        snprintf( command, DFLTBUFFERSIZE, 
                  "%s --create-home -d /tmp/home/%s %s -p %s %s &>/dev/null",
                   USERADD_BIN, username_in, main_group, DFLTPASSWD_CRYPTED, username_in 
               );
               
        if ((status=system(command)) != -1) {
            if (WEXITSTATUS(status) == 0) {
                if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                    if (createHandle(INTERNAL_STORAGE_BASE,"users",username_in,userhandle_out)) {
                                       
                        tmp_result=true;
                    }
                }
            }
        } 

        return(tmp_result);
}


/**
 *  Remove user (and its home) from the tested system.
 *
 *  @param userhandle_in (c-string) hast to contain the handle of the user to be deleted
 *  @returns true if user was successfully deleted, false otherwise
 */
bool delUser(char *userhandle_in)
{
        bool tmp_result=false;
        int status;
        char username[MAXFILENAMELEN];
        char command[DFLTBUFFERSIZE];


        /*trivial pointer checks*/
        assert(userhandle_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,username)) {

                        /*now we create the command to delete the user*/
                        snprintf( command, DFLTBUFFERSIZE,
                                  "%s --remove-home -f %s &>/dev/null",
                                  USERDEL_BIN, username
                                 );
                        //printf("DEBUG: del user via cmd:%s\n",command);

                        if ((status=system(command)) != -1) {
                                if (WEXITSTATUS(status) == 0)
                                        tmp_result=true;
                        } else {
                                PRINTQAERROR("systemcall had error");
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Add user to a specified group.
 *  In case the group does not exist addToGroup fails.
 *
 *  @param userhandle_in (c-string) handle of the user to be modified
 *  @param groupname_in (c-string) name of the group the user is to be added to
 *  @return true if user was successfully added, false otherwise
 */
bool addToGroup(char *userhandle_in, char *groupname_in)
{
        bool tmp_result=false;
        int status;
        char username[MAXFILENAMELEN];
        char command[DFLTBUFFERSIZE];


        /*trivial pointer checks*/
        assert(userhandle_in);
        assert(groupname_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,username)) {

                        /*now we create the command to modify the user*/
                        snprintf(command,DFLTBUFFERSIZE,
                                "%s -A %s %s &>/dev/null",
                                GROUPMOD_BIN, username, groupname_in
                               );
                        //printf("DEBUG: add user to group via cmd:%s\n",command);

                        if ((status=system(command)) != -1) {
                                if (WEXITSTATUS(status) == 0)
                                        tmp_result=true;
                        } else {
                                PRINTQAERROR("systemcall had error");
                        }
                }
        }

        return(tmp_result);
}



/**
 *  Remove user from a specified group.
 *
 *  @param userhandle_in (c-string) handle of the user to be modified
 *  @param groupname_in (c-string) name of the group to be removed
 *  @return true if user was successfully added, false otherwise
 */
bool removeFromGroup(char *userhandle_in, char *groupname_in)
{
        bool tmp_result=false;
        int status;
        char username[MAXFILENAMELEN];
        char command[DFLTBUFFERSIZE];


        /*trivial pointer checks*/
        assert(userhandle_in);
        assert(groupname_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,username)) {

                        /*now we create the command to modify the user*/
                        snprintf(command,DFLTBUFFERSIZE,
                                "%s -R %s %s &>/dev/null",
                                GROUPMOD_BIN, username, groupname_in
                               );

                        if ((status=system(command)) != -1) {
                                if (WEXITSTATUS(status) == 0)
                                        tmp_result=true;
                        } else {
                                PRINTQAERROR("systemcall had error");
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Translates the handle to the username.
 *
 *  @param userhandle_in (c-string) has to contain the handle of the user to be resolved
 *  @param username_out pointer to char-array to put the username in
 *  @return true if user was successfully resolved, false otherwise
 */
bool getUser(char *userhandle_in, char *username_out)
{
        bool tmp_result=false;
        char username[MAXFILENAMELEN];


        /*trivial pointer checks*/
        assert(userhandle_in);
        assert(username_out);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,username)) {

                                strcpy(username_out,username);
                                tmp_result=true;
                }
        }

        return(tmp_result);
}


/**
 *  Get the Groups the user is member of.
 *
 *  @param userhandle_in (c-string) has to contain the handle of the user to be found
 *  @param groupnames_out point to char array to put the found groupnames in (as csv)
 *  @return true if user was found, false otherwise
 */
bool getGroups(char *userhandle_in, char *groupnames_out)
{
        bool tmp_result=false;
        int status,counter;
        char username[MAXFILENAMELEN];
        char tmpfile[MAXFILENAMELEN];
        char command[DFLTBUFFERSIZE];
        char buffer[DFLTBUFFERSIZE];
        FILE *fp;
        int fd;


        /*trivial pointer checks*/
        assert(userhandle_in);
        assert(groupnames_out);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,username)) {

                        /*now we create the command to find the users groups*/
                        strcpy(tmpfile,"/tmp/rdqainternalXXXXXX");
                        if ((fd = mkstemp(tmpfile)) == -1) {
                            perror("Unable to create temporary file: ");
                        }
                        close(fd);

                        snprintf(command,DFLTBUFFERSIZE,
                                "%s -Gn %s > %s",
                                ID_BIN, username,tmpfile 
                               );
                        //printf("DEBUG: find groups via cmd:%s\n",command);

                        if ((status=system(command)) != -1) {
                                if (WEXITSTATUS(status) == 0) {
                                        if ((fp=fopen(tmpfile,"r")) != NULL) {

                                                if (fgets(buffer,sizeof(buffer),fp) != NULL) {

                                                        for (counter=0; counter < strlen(buffer);counter++) {
                                                                if (*(buffer + counter) == ' ')  {
                                                                        *(buffer+counter)=',';
                                                                }
                                                        }
                                        
                                                        strcpy(groupnames_out,buffer);        
                                                        tmp_result=true;
                                                }


                                                assert(fclose(fp) == 0);
                                        
                                        } else {
                                                PRINTQAERROR("openen internal tmp-file with id-output");
                                        }
                                }
                        } else {
                                PRINTQAERROR("systemcall had error");
                        }

                        remove(tmpfile);
                }
        }

        return(tmp_result);
}

/**
 * Change user's password.
 *
 *  @param userhandle_in (c-string) has to contain the handle of the user 
 *  @param password_in the new password
 *  @return true if the pasword was successfuly changed, false otherwise
 */
bool changePassword(char *userhandle_in, char *password_in) 
{
    bool tmp_result=false;
    char username[MAXFILENAMELEN];
    char command[DFLTBUFFERSIZE];
    int status;


    /*trivial pointer checks*/
    assert(userhandle_in);
    assert(password_in);

    if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
       if (resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,username)) {

           /*now we create the command to modify the user (btw. nobody is
            * saying that this is secure...) */
           snprintf(command,DFLTBUFFERSIZE,
                       "echo %s | %s --stdin %s &>/dev/null",
                       password_in, PASSWD_BIN, username 
                   );

           if ((status=system(command)) != -1) {
                   if (WEXITSTATUS(status) == 0)
                           tmp_result=true;
           } else {
                   PRINTQAERROR("systemcall had error");
           }
       }
    }

    return(tmp_result);
}
