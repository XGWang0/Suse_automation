/*
 * libqainterl:error.h
 * Copyright ?
 * Description: 
 */

#include <stdbool.h>

#include "global.h"
#include "handlemanager.h"

#ifndef LIBQAINTERNAL_ERROR_H
#define LIBQAINTERNAL_ERROR_H

/*error reporting*/
#define PRINTQAERROR(x) printQAError(__func__ , __FILE__ , __LINE__ ,x)


bool printQAError(const char funcname_in[],char *filename_in,int linenr,char *description);

#endif
