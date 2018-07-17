/* libqainternal: compare.c
 * Copyright ?
 * The comparison functions of libqainternal
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

#include "global.h"

#include "libqainternal.h"

#include "md5.h"

/*
 * ------------- compare functions ----------------------
 */

/**
 * Compare teststring and the corresponding md5sum.
 *
 * @param source pointer to source
 * @param src_len amount of bytes in source
 * @param reference md5sum of reference to compare (as c string)
 * @return true if build md5sum and reference are equal, else false
 */
bool md5Compare(char *source, unsigned int src_len, char *reference)
{
        bool tmp_result=true;
        unsigned int counter;

        md5_context ctx;
        unsigned char buffer;
        unsigned char hash[16]; /* only for md5 */
        char hash_hex[3];

        /*trivial param checks*/
        assert(source);
        assert(src_len);
        assert(reference);


        /*init hashing*/
        md5_starts(&ctx);
                        
        /*BUILDING MD5sum:*/
        for (counter=0; counter < src_len-1 ; counter++) {
                buffer = *(source+counter);
                md5_update(&ctx,&buffer,1);
        }
        /*finally build md5sum*/
        md5_finish(&ctx,hash);
 
        /*compare md5sums*/
        for (counter=0; counter < sizeof(hash); counter++) {
 
                /*get hash hex representation*/
                sprintf(hash_hex,"%.2x",hash[counter]);
 
                /*do real comparison*/
                if (strncasecmp(hash_hex,(reference + (counter*2)),2) != 0) {
                        tmp_result=false;
                        break;
                }
        }
 

        return(tmp_result);
}

/**
 *  Compare two strings.
 *
 *  @param result first c-string to compare
 *  @param reference second c-string to compare (with frist)
 *  @return true if both strings match, false otherwise
 */
bool strCompare(char *result, char *reference)
{
        bool tmp_result=true;

        /*trivial checks for parameters*/
        assert(result);
        assert(reference);

        if (strcmp(result,reference) != 0) {
                tmp_result=false;
        }

        return(tmp_result);
}

/**
 *  Compare n first characters of two strings.
 *
 *  @param result first data string
 *  @param reference second data string to compare (with first)
 *  @param len how many bytes (from beginning) should be compared
 *  @return true if both strings match, false otherwise
 */
bool strnCompare(char *result, char *reference, unsigned int len)
{
        bool tmp_result=true;
        unsigned int counter;

        /*trivial check for parameters*/
        assert(result);
        assert(reference);
        assert(len);

        for(counter=0; counter < len; counter++) {
                if (result[counter] != reference[counter]) {
                        tmp_result=false;
                        break;
                }
        }

        return(tmp_result);
}

