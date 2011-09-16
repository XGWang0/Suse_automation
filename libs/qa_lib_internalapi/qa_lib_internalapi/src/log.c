/* libqainternal: log.c
 * Copyright ?
 * The log/print handling functions of libqainternal
 */


#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "handlemanager.h"
#include "global.h"

/** Print status/info/warning/error/ message.
  * Print message in standard formating. Possible message levels are:
  *  - MSG_ERROR: an error occured
  *  - MSG_INFO: print some information
  *  - MSG_WARN: warning
  *  - MSG_PASSED: test passed
  *  - MSG_FAILED: test failed
  *  - MSG_SKIPPED: test skipped
  *
  * In addition to this function the following aliases (macros) exists:
  *  - printError(const char *message, ...)
  *  - printInfo(const char *message, ...)
  *  - printWarning(const char *message, ...)
  *  - printPassed(const char *message, ...)
  *  - printFailed(const char *message, ...)
  *  - print(const char *message, ...)
  *
  * @param level message level (one of the MSG_*)
  * @param message message/format string (same as in printf)
  * @param ... variable length arguments
  * @return false in case of I/O error, true otherwise
  */
bool printMessage(enum LogLevel level, const char *message, ...) 
{
    va_list arg;
    int done;
    
    switch (level) {
        case MSG_WARN: 
            printf("(W) ");
            break;
            
        case MSG_ERROR:
            printf("(E) ");
            break;
       
        case MSG_INFO:
            printf("(I) ");
            break;
      
        case MSG_PASSED:
            printf("PASSED: ");
            break;
     
        case MSG_FAILED:
            printf("FAILED: ");
            break;

        case MSG_SKIPPED:
            printf("SKIPPED: ");
            break;

        case MSG_NOFLAG:
            break;
            
        default:
            break;
    }

    va_start(arg, message);
    done = vprintf(message,arg);
    va_end(arg);
    printf("\n");
    return (done >= 0) ? true : false;
}
