/* libqainternal.c - testscript api for rd-qa
 * Copyrtight ?
 * Description: central definitions of libqainternal api
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <sys/types.h>
#include <ctype.h>
#include <assert.h>

#include "libqainternal.h"



/*just a supertrivial first fucntion for compiletests */
void qa_hello(void) {
	printf("libqainternal (version %s by %s) says hello to the world ;-)\n",qa_internal_version,qa_internal_author);
	return;
}
