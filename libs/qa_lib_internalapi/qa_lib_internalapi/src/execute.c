/* libqainternal: execute.c
 * Copyright ?
 * The execute functions of libqainternal
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
#include <signal.h>
#include <sys/vfs.h>
#include <assert.h>
#include <libgen.h>
#include <dirent.h>

#include "global.h"
#include "error.h"

#include "execute.h"

#include "libqainternal.h"

/*
 * ------------- execute functions ----------------------
 */

/**
 *  Get a handle for a command.
 *
 *  @param commandhandle_out will be used to give back the handle (c-string)
 *  @param command_in has to contain a c-string with the commands name or path
 *  @param options_in (c-string) may contain options to be given to command
 *  @return true if got successfully associated, false otherwise
 */
bool associateCmd(char *commandhandle_out, char *command_in, char *options_in)
{
        bool tmp_result=false;
        char completecommand[DFLTBUFFERSIZE];

        /*trivial pointer checks*/
        assert(commandhandle_out);
        assert(command_in);
        assert(options_in);

        snprintf( completecommand,DFLTBUFFERSIZE,
                  "%s %s",command_in, options_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
            if (createHandle(INTERNAL_STORAGE_BASE,"commands",completecommand, commandhandle_out)) {
                tmp_result=true;
            }
        }

        return(tmp_result);
}


/**
 *  Execute command represented by command handle and wait for the result.
 *  This function executes synchronously the given command.
 * 
 *  @param commandhandle_in (c-string) has to contain the handle of the command to start
 *  @return true if command was successfully run, false otherwise
 */
bool runCmd(char *commandhandle_in)
{
        bool tmp_result=false;
        int status;
        char command[MAXFILENAMELEN];


        /*trivial pointer checks*/
        assert(commandhandle_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,commandhandle_in,command)) {

                        /*now we really run the command*/

                        if ((status=system(command)) != -1) {
                                if (WEXITSTATUS(status) == 0)
                                        tmp_result=true;
                        } else {
                                PRINTQAERROR("error on systemcall of command");
                        }
                }
        }

        return(tmp_result);
}



/**
 *  Execute command as a given user.
 *  This function executes synchronously the given command as a given user.
 *  The command will be executed in different process thus the uid of the
 *  test-script will not be affected.
 *
 *  NOTE: you have to be root to use this function (due to setuid call)
 *
 *  @param commandhandle_in (c-string) has to contain the handle of the command to start
 *  @param userhandle_in (c-string) has to contain the user(s-handle) to start the command as
 *  @return true if command was successfully run, false otherwise
 */
bool runCmdAs(char *commandhandle_in, char *userhandle_in)
{
        bool tmp_result=false;
        int status,stat2;
        char command[MAXFILENAMELEN];
        char user[MAXFILENAMELEN];
        char buffer[DFLTBUFFERSIZE];
        int new_user_id=-1;
        pid_t child;
        FILE *fp;


        /*trivial pointer checks*/
        assert(commandhandle_in);
        assert(userhandle_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,commandhandle_in,command) && 
                    resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,user)) {


                        /*get the uid of the user specified*/
                        if ((fp=fopen(PASSWD,"r")) != NULL) {
                                while(fgets(buffer,sizeof(buffer),fp) != NULL) {
                                        if (strstr(buffer,user) != NULL) {
                                                /*we have the line with the user*/
                                                /*now we extract the uid*/
                                                sscanf(buffer,"%*[^:]:%*[^:]:%d",&new_user_id);
                                                //printf("DEBUG:found user with id %d\n",new_user_id);
                                                break;
                                        }
                                }

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("opening /etc/passwd");
                        }


                        if (new_user_id > -1) {
                                //printf("DEBUG: we shall use the new userid %d\n",new_user_id);

                                if ((child=fork()) == 0) {
                                        /*we are the child*/

                                        /*now we try to become the user of the userhandle, after we forked*/
                                        if (setuid(new_user_id) == 0) {

                                                /*and process the command if it worked..*/
                                                status=system(command);
                                                exit(WEXITSTATUS(status));

                                        } else {
                                                PRINTQAERROR("trying to become other user");
                                        }

                                        exit(1);
                                } else {
                                        /*we are the parent*/
                                        wait(&stat2);

                                        if (WEXITSTATUS(stat2) == 0) {
                                                tmp_result=true;
                                        }
                                }
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Execute command asynchronously.
 *  This function executes asynchronously the given command as a given user.
 *  The command will be executed in different process thus the uid of the
 *  test-script will not be affected.
 *
 *  @param commandhandle_in (c-string) has to contain the handle of the command to start async
 *  @param userhandle_in (c-string) has to contain the user(s-handle) to start the command as
 *  @return true if command was successfully run, false otherwise
 */
bool runCmdAsyncAs(char *commandhandle_in, char *userhandle_in)
{
        bool tmp_result=false;
        int status;
        char command[MAXFILENAMELEN];
        char user[MAXFILENAMELEN];
        char buffer[DFLTBUFFERSIZE];
        int new_user_id=-1;
        pid_t child;
        FILE *fp;


        /*trivial pointer checks*/
        assert(commandhandle_in);
        assert(userhandle_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,commandhandle_in,command) && 
                    resolveHandle(INTERNAL_STORAGE_BASE,userhandle_in,user)) {


                        /*get the uid of the user specified*/
                        if ((fp=fopen(PASSWD,"r")) != NULL) {
                                while(fgets(buffer,sizeof(buffer),fp) != NULL) {
                                        if (strstr(buffer,user) != NULL) {
                                                /*we have the line with the user*/
                                                /*now we extract the uid*/
                                                sscanf(buffer,"%*[^:]:%*[^:]:%d",&new_user_id);
                                                //printf("DEBUG:found user with id %d\n",new_user_id);
                                                break;
                                        }
                                }

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("opening /etc/passwd");
                        }


                        if (new_user_id > -1) {
                                //printf("DEBUG: we shall use the new userid %d\n",new_user_id);

                                if ((child=fork()) == 0) {
                                        /*we are the child*/

                                        /*now we try to become the user of the userhandle, after we forked*/
                                        if (setuid(new_user_id) == 0) {

                                                /*and process the command if it worked..*/
                                                status=system(command);
                                                exit(WEXITSTATUS(status));

                                        } else {
                                                PRINTQAERROR("trying to become other user");
                                        }

                                        exit(1);
                                } else {
                                        /*we are the parent*/
                                        tmp_result=true;
                                }
                        }
                }
        }

        return(tmp_result);
}

/**
 *  Execute command asynchornously.
 *
 *  This function executes asynchronously the given command.
 *  The command will be executed in different process thus the uid of the
 *  test-script will not be affected.
 *
 *  Param commandhandle_in: (c-string) has to contain the handle of the command to start async
 *  Returns: true if command was successfully run, false otherwise
 */
bool runCmdAsync(char *commandhandle_in)
{
        bool tmp_result=false;
        int status;
        char command[MAXFILENAMELEN];
        pid_t child;


        /*trivial pointer checks*/
        assert(commandhandle_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,commandhandle_in,command)) {


                        if ((child=fork()) == 0) {
                                /*we are the child*/

                                        /*process the command*/
                                        status=system(command);
                                        exit(WEXITSTATUS(status));

                        } else {
                                /*we are the parent*/
                                tmp_result=true;
                        }
                }
        }

        return(tmp_result);
}

/**
 * Execute command asynchronously and return the pid of the child process.
 *
 * NOTE: you have to be root to use this function (due to setuid call)
 *
 *  @param commandhandle_in (c-string) has to contain the handle of the command to be started async(!!!)
 *  @param pid_out point to usigned int where the pid of the newly started command will be stored
 *  @return true if command was successfully started, false otherwise
 */
bool pidOfCmd(char *commandhandle_in, unsigned int *pid_out)
{
        bool tmp_result=false;
        int status;
        char command[MAXFILENAMELEN];
        char file[MAXFILENAMELEN];
        int counter,argcounter=0,beg_nxt;
        pid_t child;


        /*trivial pointer checks*/
        assert(commandhandle_in);
        assert(pid_out);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,commandhandle_in,command)) {


                        if ((child=fork()) == 0) {
                                /*we are the child*/

                                        /*we seperate the first element of the cmd*/
                                        for (counter=0; counter < strlen(command);counter++) {
                                                if (*(command + counter) == ' ' &&
                                                    counter > 0 &&
                                                    (counter+1) < strlen(command)) {
                                                        
                                                        if (argcounter == 0) {
                                                                strncpy(file,command,counter);
                                                                file[counter]='\0';
                                                                argcounter++;
                                                                beg_nxt=counter+1;
                                                                break;
                                                        }
                                                }
                                        }

                                        /*process the command*/
                                        //printf("DEBUG: file=%s, args=%s\n",file,(command+beg_nxt));
                                        status=execlp(file,file,(command + beg_nxt),(char *)NULL);
                                        exit(WEXITSTATUS(status));

                        } else {
                                /*we are the parent*/
                                *pid_out=(unsigned int)child;
                                tmp_result=true;
                        }
                }
        }

        return(tmp_result);
}


/**
 * Kill the given process.
 *
 *  @param pid_in pid of the process to kill
 *  @return true if process was successfully killed, false otherwise
 */
bool killPid(unsigned int pid_in)
{
        bool tmp_result=false;

        if (kill(pid_in,SIGTERM) == 0) {
                tmp_result=true;
        } else {
                PRINTQAERROR("killPid:with SIGTERM");

                /*hm, we now try with SIGKILL*/
                if (kill(pid_in,SIGKILL) == 0) {
                        tmp_result=true;
                } else {
                        PRINTQAERROR("killPid:with SIGKILL");
                }
        }

        return(tmp_result);
}

