/* libqainternal: error.c
 * Copyright ?
 * The error-handlingfunctions of libqainternal
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

#include "libqainternal.h"

/*
 * ------------- error functions ----------------------
 */

/*
 *  Internal errorprinting....
 *  Params are selfexplaining...
 *  Returns: true if successfull, false otherwise
 */
bool printQAError(const char funcname_in[],char *filename_in,int linenr,char *description)
{
	bool tmp_result=false;
	char buffer[DFLTBUFFERSIZE];

	/*trivial pointer checks*/
	assert(funcname_in);
	assert(filename_in);
	assert(linenr >-1);
	assert(description);

	if (sprintf(buffer,"libqainternal:%s(%s:%d):%s",funcname_in,filename_in,linenr,description) > 0) {
		perror(buffer);	
	
		tmp_result=true;
	}


	return(tmp_result);
}



