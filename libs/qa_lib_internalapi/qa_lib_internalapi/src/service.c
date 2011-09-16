/* libqainternal: service.c
 * Copyright ?
 * The service handling functions of libqainternal
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

#include "service.h"

#include "libqainternal.h"

/*
 * ------------- service functions ----------------------
 */



/* forward declaration of "private" functions. */
/** @cond PRIVATE */
bool checkRoot();
bool serviceFunction(char *servicehandle_in, const char *action);
/** @endcond */

/**
 *  Create handle from a service name.
 *
 *  This function translates a servicename to a handle which can be used
 *  for stoping/starting/etc of the service.
 *
 *  @param servicehandle_out will be used to give back the handle (c-string)
 *  @param servicename_in has to contain a c-string with the services name
 *  @return true if got successfully associated, false otherwise
 */
bool associateService(char *servicehandle_out, char *servicename_in)
{
        bool tmp_result=false;

        /*trivial pointer checks*/
        assert(servicehandle_out);
        assert(servicename_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
            if (createHandle(INTERNAL_STORAGE_BASE,"services",servicename_in, servicehandle_out)) {
                    
                /*give back servicehandle*/
                tmp_result=true;
            }
        }

        return(tmp_result);
}


/**
 *  Check if the service is running.
 *
 *  This is equivalent to executing "/etc/init.d/SERVICE status".
 *  NOTE: you must be root to use this function
 *
 *  @param servicehandle_in (c-string) hast to contain the handle of the service to check
 *  @return true if service is really running, false otherwise
 */
bool checkService(char *servicehandle_in)
{
    return serviceFunction(servicehandle_in, "status");
}


/**
 *  Start the service.
 *
 *  NOTE: you must be root to use this function.
 *
 *  @param servicehandle_in (c-string) hast to contain the handle of the service to start
 *  @return true if service was really started, false otherwise
 */
bool startService(char *servicehandle_in)
{
    return serviceFunction(servicehandle_in, "start" );
}


/**
 *  Stop the given service.
 *
 *  NOTE: you must be root to use this function
 *
 *  @param servicehandle_in (c-string) hast to contain the handle of the service to stop
 *  @return true if service was really stopped, false otherwise
 */
bool stopService(char *servicehandle_in)
{
    return serviceFunction(servicehandle_in, "stop" );
}


/**
 *  Restart the given service.
 *  NOTE: you must be root to execute this function
 *
 *  Param servicehandle_in: (c-string) hast to contain the handle of the
 *  service to restart
 *  Returns: true if service was really re-started, false otherwise
 */
bool restartService(char *servicehandle_in)
{
    return serviceFunction(servicehandle_in, "restart" );
}

/**
 *  Reload the given service.
 *  NOTE: you must be root to execute this function
 *
 *  Param servicehandle_in: (c-string) hast to contain the handle of the
 *  service to reload
 *  Returns: true if service was really re-loaded, false otherwise
 */
bool reloadService(char *servicehandle_in)
{
    return serviceFunction(servicehandle_in, "reload" );
}

/**
 *  Return open ports of a given service.
 *
 *  @param servicehandle_in (c-string) hast to contain the handle of the service to check
 *  @param openports_out pointer to first port number
 *  @param openportscount_out number of openports found and put after openports_out
 *  @return true if service if scan for ports was successfull, false otherwise
 */
bool openportsOfService(char *servicehandle_in, unsigned int *openports_out, int *openportscount_out)
{
        bool tmp_result=false;
        int status;
        char servicename[MAXFILENAMELEN];
        char pidofproccmd[MAXFILENAMELEN];
        char initscript[MAXFILENAMELEN];
        char tmpfile[MAXFILENAMELEN];
        char searchstr[MAXFILENAMELEN];
        char buffer[DFLTBUFFERSIZE];
        char buf2[DFLTBUFFERSIZE];
        char basen[MAXFILENAMELEN];
        char filename[MAXFILENAMELEN];
        char linkname[MAXFILENAMELEN];
        int linksize;
        unsigned int pids[DFLTBUFFERSIZE];
        unsigned int *cur_pid;
        unsigned int sockets[DFLTBUFFERSIZE];
        unsigned int *cur_socket;
        unsigned int ports[DFLTBUFFERSIZE];
        unsigned int *cur_port;
        int tmp_int , int_tmp2;
        char procpath[DFLTBUFFERSIZE];
        char *foundstr=NULL;
        FILE *fp;
        int fd;
        DIR *directory;
        struct dirent *dir_info;

        /*trivial pointer checks*/
        assert(servicehandle_in);
        assert(openports_out);

        if (( is_storageready(INTERNAL_STORAGE_BASE) ||
                init_handlemanager(INTERNAL_STORAGE_BASE)) && 
              resolveHandle(INTERNAL_STORAGE_BASE,servicehandle_in,servicename)) {

               /* Check if either we are root or we can do
                * setuid(0) */

               if (checkRoot()) {

                       /*so, now we really start to check for the openports*/
                       snprintf(initscript,MAXFILENAMELEN,"/etc/init.d/%s",servicename);

                       strcpy(searchstr,"_BIN=/");

                       /*now we lookup the absolute-bin-path in the init-script*/
                       if ((fp=fopen(initscript,"r")) == NULL) {
                           PRINTQAERROR("trying to parse initscript for bin-path");
                           return tmp_result;
                       } 
                     
                       while (fgets(buffer,DFLTBUFFERSIZE,fp)!= NULL) {
                               if ((foundstr=strstr(buffer,searchstr)) != NULL) {
                                       foundstr += strlen(searchstr)-1;
                                       break;
                               }
                       }
                       
                       assert(fclose(fp) == 0);

                       if (foundstr == NULL) {
                           return tmp_result;
                       }

                       /*yes, we have the path to the services bin :) */

                       strcpy(basen,basename(foundstr));

                       /*generate checkpid command*/
                       strcpy(pidofproccmd,"/sbin/pidofproc -v ");
                       for (tmp_int=0; tmp_int < strlen(basen); tmp_int++) {
                               if (isgraph(*(basen + tmp_int))) {
                                       strncat(pidofproccmd, basen+tmp_int,1);
                               }
                       }
                       
                       strcat(pidofproccmd," &> ");
                       strcpy(tmpfile,"/tmp/rdqainternalXXXXXX");
                       if ((fd = mkstemp(tmpfile)) == -1) {
                            perror("Unable to create temporary file: ");
                       }
                       close(fd);
                       strcat(pidofproccmd,tmpfile);
                       //printf("DEBUG: using cmd %s\n",pidofproccmd);

                       if ((status=system(pidofproccmd)) != -1) {
                               if (WEXITSTATUS(status) == 0)  {
                                       if ((fp=fopen(tmpfile,"r")) != NULL) {

                                               cur_pid=pids;
                                               while (fscanf(fp,"%u",cur_pid) > 0 ) {        
                                                       //printf("DEBUG:found pid %u\n",*cur_pid);
                                                       cur_pid++;
                                               } 
                       
                                               assert(fclose(fp) == 0);

                                               if (cur_pid > pids) {
                                                       /*we found the pids of the service*/
                                                       /*but we need the sockets opened */

                                                       cur_socket=sockets;
                                                       for(tmp_int=0; (pids + tmp_int) < cur_pid; tmp_int++) {
                                                               sprintf(procpath,"/proc/%u/fd",pids[tmp_int]);
                                                               //printf("DEBUG:procpath:/proc/%u/fd\n",pids[tmp_int]);

                                                               if ((directory=opendir(procpath)) != NULL) {
                                                                       while ((dir_info=readdir(directory)) != NULL) {
                                                                               //printf("DEBUG:found:%s\n",dir_info->d_name);
                                                                               
                                                                               strcpy(filename,procpath);
                                                                               strcat(filename,"/");
                                                                               strcat(filename,dir_info->d_name);
                                                                               if ((linksize=readlink(filename,linkname,MAXFILENAMELEN)) > 0) {
                                                                                       *(linkname + linksize)='\0';
                                                                                       if (strncmp(linkname,"socket:[",8) == 0) {
                                                                                               int_tmp2=strlen(linkname)-9;
                                                                                               strncpy(buffer,linkname + 8,int_tmp2);
                                                                                               *(buffer+int_tmp2)='\0';
                                                                                               *cur_socket = (unsigned int) atoll(buffer);
                                                                                               //printf("DEBUG:found socket %u\n",*cur_socket);
                                                                                               cur_socket++;
                                                                                       }

                                                                               }
                                                                       }
                                                               } else {
                                                                       PRINTQAERROR("could not open the proc-dir");
                                                               }
                                                       }

                                                       /*now, we even have the sockets, but we want*/
                                                       /*the ports of them*/

                                                       if (cur_socket > sockets) {

                                                               /*TODO: get ports of processes!!!!! */
                                                       
                                                               cur_port=ports;
                                                       
                                                               if ((fp=fopen("/proc/net/tcp","r")) != NULL) {
                                                                       while (fgets(buffer,sizeof(buffer),fp) != NULL) {
                                                                               
                                                                               for(tmp_int=0; (sockets + tmp_int) < cur_socket; tmp_int++){
                                                                                       sprintf(buf2,"%u",sockets[tmp_int]);
                                                                                       if (strstr(buffer,buf2) != NULL) {
                                                                                               if (sscanf(buffer," %*[0-9]: %*[0-9]:%X",cur_port) > 0) {
                                                                                                       //printf("DEBUG: found open port %u in tcp\n",*cur_port);
                                                                                                       cur_port++;
                                                                                               }
                                                                                       }
                                                                               }
                                                                       }
                                                                       
                                                               
                                                               } else {
                                                                       PRINTQAERROR("open of /proc/net/tcp");
                                                               }

                                                               if ((fp=fopen("/proc/net/tcp6","r")) != NULL) {
                                                                       while (fgets(buffer,sizeof(buffer),fp) != NULL) {
                                                                               
                                                                               for(tmp_int=0; (sockets + tmp_int) < cur_socket; tmp_int++){
                                                                                       sprintf(buf2,"%u",sockets[tmp_int]);
                                                                                       if (strstr(buffer,buf2) != NULL) {
                                                                                               if (sscanf(buffer," %*[0-9]: %*[0-9]:%X",cur_port) > 0) {
                                                                                                       //printf("DEBUG: found open port %u in tcp6\n",*cur_port);
                                                                                                       cur_port++;
                                                                                               }
                                                                                       }
                                                                               }
                                                                       }
                                                                       
                                                               
                                                               } else {
                                                                       PRINTQAERROR("open of /proc/net/tcp6");
                                                               }

                                                               if ((fp=fopen("/proc/net/udp","r")) != NULL) {
                                                                       while (fgets(buffer,sizeof(buffer),fp) != NULL) {
                                                                               
                                                                               for(tmp_int=0; (sockets + tmp_int) < cur_socket; tmp_int++){
                                                                                       sprintf(buf2,"%u",sockets[tmp_int]);
                                                                                       if (strstr(buffer,buf2) != NULL) {
                                                                                               if (sscanf(buffer," %*[0-9]: %*[0-9]:%X",cur_port) > 0) {
                                                                                                       //printf("DEBUG: found open port %u in udp\n",*cur_port);
                                                                                                       cur_port++;
                                                                                               }
                                                                                       }
                                                                               }
                                                                       }
                                                                       
                                                               
                                                               } else {
                                                                       PRINTQAERROR("open of /proc/net/udp");
                                                               }

                                                               if ((fp=fopen("/proc/net/udp6","r")) != NULL) {
                                                                       while (fgets(buffer,sizeof(buffer),fp) != NULL) {
                                                                               
                                                                               for(tmp_int=0; (sockets + tmp_int) < cur_socket; tmp_int++){
                                                                                       sprintf(buf2,"%u",sockets[tmp_int]);
                                                                                       if (strstr(buffer,buf2) != NULL) {
                                                                                               if (sscanf(buffer," %*[0-9]: %*[0-9]:%X",cur_port) > 0) {
                                                                                                       //printf("DEBUG: found open port %u in udp6\n",*cur_port);
                                                                                                       cur_port++;
                                                                                               }
                                                                                       }
                                                                               }
                                                                       }
                                                                       
                                                               
                                                               } else {
                                                                       PRINTQAERROR("open of /proc/net/udp6");
                                                               }

                                                               if (cur_port > ports) {
                                                                       /* yes, now finally we have the ports*/
                                                                       /* so we put them in the callers array*/
                                                                       tmp_result=true;
                                                                       
                                                                       for(tmp_int=0; (ports + tmp_int) < cur_port; tmp_int++) {
                                                                               *(openports_out + tmp_int) = ports[tmp_int];
                                                                       }
                                                                       
                                                                       /*also report amount of found open ports*/
                                                                       *openportscount_out= cur_port - ports;
                                                               }
                                                       }
                                               }

                                       } else {
                                               PRINTQAERROR("open of internal tmpfile");
                                       }
                               } 
                       } else {
                               PRINTQAERROR("run of checkproc");
                       }
                       
                       /* cleanup our internal tmp-file*/
                       assert(remove(tmpfile) == 0);
               } else {
                       PRINTQAERROR("openportsOfService wont work if not run as root");
               }
        }

        return(tmp_result);
}



/*
 * ------------- private helper functions ----------------------
 */



/** @cond PRIVATE
 * Check if we are root.
 * In case we are not running as root try to setuid(0).
 *
 * @return true if we are root or the setuid(0) call for successful. false
 * otherwise.
 */

bool checkRoot()
{
    /*but we have to run as root ...*/
    if (getuid() == 0) {
            /*yes, we are running as root*/

            return true;
    } else {
            /*no, we are not running as root ... */
            /*but we could at least try a setuid..*/
            if (setuid(0) == 0) {
                    /*yes, it worked :)*/
                    return true;
            } else {
                    /*mhh, at least we tried to do it :(*/
                    PRINTQAERROR("cannot become root");
            }
    }
    return false;
}

/**
  * Common body for all service functions. 
  * This is where all the functionality is implemented. All other functions
  * are just calling this with a special parameter.
  *
  * Don't use this function in test scripts!
  *
  * @param servicehandle_in service handle
  * @param action one of the following: start stop, restart, reload, status
  */
bool serviceFunction(char *servicehandle_in, const char *action) 
{
        bool tmp_result=false;
        int status;
        char servicename[MAXFILENAMELEN];
        char initscript[MAXFILENAMELEN];


        /*trivial pointer checks*/
        assert(servicehandle_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,servicehandle_in,servicename)) {

                        /* Check if either we are root or we can do
                         * setuid(0) */

                        if (checkRoot()) {

                                /*so, now we really stop the service*/
                                snprintf(initscript, MAXFILENAMELEN, 
                                         "/etc/init.d/%s %s",servicename, action);

                                if ((status=system(initscript)) != -1) {
                                        if (WEXITSTATUS(status) == 0)
                                                tmp_result=true;
                                } else {
                                        PRINTQAERROR("systemcall to stop service did not work");
                                }


                        } else {
                                PRINTQAERROR("stopService wont work if not run as root");
                        }
                }
        }

        return(tmp_result);
}

/** @endcond
 */
