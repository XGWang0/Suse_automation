/*
 * libqainterl:libqainternal.h
 * Copyright ?
 * Description: central lib defintions...
 */
/** 
 * @mainpage libqainternal
 * 
 * @section intro Introduction
 *
 * libqainternal is a library with functions which are often needed while
 * automating tests and its main purpose is to make writing of automated
 * tests easier.
 *
 * The functions are divided into the following categories:
 *  - @link user.c user related functions @endlink
 *  - @link file.c file related functions @endlink
 *  - @link service.c service related functions @endlink
 *  - @link compare.c comparing @endlink
 *  - @link execute.c execution @endlink
 *  - @link config.c config files related functions @endlink
 *  - @link cleanup.c cleanup @endlink
 *  - @link log.c logging/printing functions @endlink
 *
 * @section concepts Basic concepts
 *  - functions return boolean value 
 *  - Almost all objects (users, commands, files) are accessed via
 *  "handle". Handle is a string identifier - note that you are responsible
 *  to create buffer which is big enough! buffer[MAXHANDLESIZE]
 *  should be a good choice.
 *  - you should use PASSED, FAILED, SKIPPED and ERROR macros as exit code 
 *  in your test scripts
 *  - use @link log.c printMessage @endlink function or its aliaes
 *  (printWarning, printError, printPassed, ...) for reporting errors,
 *  information and passed/failed messages so the testscripts have a common
 *  output
 */

#include <stdbool.h>


#ifndef LIBQAINTERNAL_LIBQAINTERNAL_H
#define LIBQAINTERNAL_LIBQAINTERNAL_H

#define MAXFILENAMELEN FILENAME_MAX
#define MAXHANDLESIZE MAXFILENAMELEN

#define PASSED 0
#define FAILED 1
#define ERROR 11
#define SKIPPED 22

enum LogLevel{ MSG_WARN, MSG_ERROR, MSG_INFO, MSG_FAILED, MSG_PASSED, MSG_NOFLAG, MSG_SKIPPED };

/** Function for cleaning up all temporary objects. 
 * @file cleanup.c
 */
bool cleanup(char *handletype_in);

/** Functions for manipulating the user database.
  * These functions provide simple functionality like addUser or delUser
  * @file user.c */
bool addUser(char *userhandle_out, char *username_in, char *group_in);
bool delUser(char *userhandle_in);
bool addToGroup(char *userhandle_in, char *groupname_in);
bool removeFromGroup(char *userhandle_in, char *groupname_in);
bool getUser(char *userhandle_in, char *username_out);
bool getGroups(char *userhandle_in, char *groupnames_out);
bool changePassword(char *userhandle_in, char *password_in);

/** Various file-related functions.
  * @file file.c
  */
bool createFile(char *filehandle_out, char *filename_in);
bool createFileMinsize(char *filehandle_out, char *filename_in, unsigned long minfilesize_in);
bool createTempFile(char *filehandle_out);
bool removeFile(char *filehandle_in);
bool lookupFile(char *filehandle_in,char *filename_out);
bool writeBinaryFile(char *filehandle_in, char *data_in, unsigned int len_in);
bool writeTextFile(char *filehandle_in, char *data_in);
bool readTextFile(char *filehandle_in, char *data_out, unsigned int *sizeread_out);
bool readTextlineFile(char *filehandle_in, char *data_out, unsigned int *sizeread_out);
bool readBinaryFile(char *filehandle_in, char *data_out, unsigned int bytestoread_in, unsigned int *sizeread_out);

/** Functions related to various services (such as ssh, apache etc). 
 * @file service.c
 */
bool associateService(char *servicehandle_out, char *servicename_in);
bool checkService(char *servicehandle_in);
bool startService(char *servicehandle_in);
bool stopService(char *servicehandle_in);
bool restartService(char *servicehandle_in);
bool openportsOfService(char *servicehandle_in, unsigned int *openports_out, int *openportscount_out); 

/** Various compare functions.
 *  @file compare.c
 */
bool md5Compare(char *source, unsigned int src_len, char *reference);
bool strCompare(char *result, char *reference);
bool strnCompare(char *result, char *reference, unsigned int len);

/** Functions related to command execution.
 *  @file execute.c
 */
bool associateCmd(char *commandhandle_out, char *command_in, char *options_in);
bool runCmd(char *commandhandle_in);
bool runCmdAs(char *commandhandle_in, char *userhandle_in);
bool runCmdAsync(char *commandhandle_in);
bool runCmdAsyncAs(char *commandhandle_in, char *userhandle_in);
bool pidOfCmd(char *commandhandle_in, unsigned int *pid_out);
bool killPid(unsigned int pid_in);

/** Functions related to config files. 
 *  @file config.c
 */
bool copyConfig(char *confighandle_out, char *testconffilename_in, char *origconffilename_in);
bool removeConfig(char *confighandle_in);
bool checkConfig(char *confighandle_in, char *origconffilename_out);

/** Logging/printing functions 
 *  @file   log.c
 */

bool printMessage(enum LogLevel level, const char * message, ...); 
#define printInfo(message,...)     printMessage(MSG_INFO, message, ##__VA_ARGS__)
#define printError(message,...)    printMessage(MSG_ERROR, message, ##__VA_ARGS__)
#define printWarning(message,...)  printMessage(MSG_WARN, message, ##__VA_ARGS__)
#define printFailed(message,...)   printMessage(MSG_FAILED, message, ##__VA_ARGS__)
#define printPassed(message,...)   printMessage(MSG_PASSED, message, ##__VA_ARGS__)
#define printSkipped(message,...)   printMessage(MSG_SKIPPED, message, ##__VA_ARGS__)
#define print(message,...)         printMessage(MSG_NOFLAG, message, ##__VA_ARGS__)

/* version */
extern char const qa_internal_version[];
extern char const qa_internal_author[];


/*selftesting*/
void qa_hello(void);

#endif
