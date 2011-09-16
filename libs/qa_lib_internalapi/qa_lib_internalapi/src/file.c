/* libqainternal: file.c
 * Copyright ?
 * The file handling functions of libqainternal
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
#include <assert.h>
#include <errno.h>

#include "global.h"
#include "error.h"

#include "file.h"

#include "libqainternal.h"

/*
 * ------------- file functions ----------------------
 */

/**
 *  Create file.
 *
 *  @param filehandle_out will be used to give back the handle
 *  @param filename_in has to contain a c-string with the filename
 *  @return true if got successfully created
 */
bool createFile(char *filehandle_out, char *filename_in)
{
        bool tmp_result=false;
        FILE *file;

        /*trivial pointer checks*/
        assert(filehandle_out);
        assert(filename_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (createHandle(INTERNAL_STORAGE_BASE,"files",filename_in, filehandle_out)) {
                        
                        /*really create file*/
                        if ((file = fopen(filename_in,"w")) != NULL) {
                            fclose(file);
                        } else {
                            perror("Unable to create file: ");
                        }

                        tmp_result=true;
                }
        }

        return(tmp_result);
}


/**
 *  Create file with a defined minimum size.
 *
 *  @param filehandle_out will be used to give back the handle
 *  @param filename_in has to contain a c-string with the filename
 *  @param minfilesize_in has to hold the amount of bytes the file will probably grow to
 *  @return true if got successfully created
 */
bool createFileMinsize(char *filehandle_out, char *filename_in, unsigned long minfilesize_in)
{
        bool tmp_result=false;
        struct statfs fs;
        unsigned long long available_bytes;
        FILE *file;

        /*trivial pointer checks*/
        assert(filehandle_out);
        assert(filename_in);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (createHandle(INTERNAL_STORAGE_BASE,"files",filename_in, filehandle_out)) {

                        /*really create file*/
                        if ((file = fopen(filename_in,"w")) != NULL) {
                            fclose(file);
                        } else {
                            perror("Unable to create file: ");
                        }
                        
                        /*now we try to determine the available amount of bytes
                          and see if it is enough for the file wanted...*/
                        if (statfs(filename_in,&fs) == 0) {

                                /*get the free bytes*/
                                available_bytes = fs.f_bsize * fs.f_bavail;
//                                printf("DEBUG: checkfilesystem: got %lld for %ld bytes\n",available_bytes,minfilesize_in);

                                if (available_bytes >= minfilesize_in) { 
                                        tmp_result=true;
                                } else {
                                        assert(remove(filename_in) == 0);
                                }
                        }
                }
        }

        return(tmp_result);
}

/**
 *  Create temporary file.
 *  
 *  @param filehandle_out will be used to give back the handle of the tmp-file
 *  @return true if got successfully created, false otherwise
 */
bool createTempFile(char *filehandle_out)
{
        bool tmp_result=false;
        char buffer[MAXFILENAMELEN];
        int fd;

        /*trivial pointer checks*/
        assert(filehandle_out);

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {

                strcpy(buffer,"/tmp/qatmpXXXXXX");
                if ((fd = mkstemp(buffer)) != -1) {
                    if ( createHandle(INTERNAL_STORAGE_BASE,"files",buffer, filehandle_out)) {
                        tmp_result=true;
                    } else {
                        unlink(buffer);
                    }
                    close(fd);
                } else {
                    perror("Unable to create file: ");
                }
        }

        return(tmp_result);
}


/**
 *  Remove file.
 *
 *  @param filehandle_in c-string with handle of file that shall be removed
 *  @returns true if handle was ok and file was removed, false otherwise
 */
bool removeFile(char *filehandle_in)
{
        bool tmp_result=false;
        char filename[MAXFILENAMELEN];

        /*trivial pointer checks*/
        assert(filehandle_in);

       if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,filename)) {
                        if (remove(filename) == 0) {
                                tmp_result=true;
                        } else {
                                PRINTQAERROR("removeFile");
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Translate file handle to a path.
 *
 *  @param filehandle_in c-string with the filehandle
 *  @param filename_out pointer to char-array where the filename will be stored(!!)
 *  @return true if file could be determined, false otherwise
 */
bool lookupFile(char *filehandle_in,char *filename_out)
{
        bool tmp_result=false;
        char buffer[MAXFILENAMELEN];

        /*trivial pointer checks*/
        assert(filehandle_in);
        assert(filename_out);
        
        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,buffer)) {
                        
                        strcpy(filename_out,buffer);
                        tmp_result=true;
                }
        }

        return(tmp_result);
}


/**
 *  Write some binary data to the file.
 *
 *  @param filehandle_in c-string with filehandle
 *  @param data_in pointer to char-array with data to write
 *  @param len_in how many bytes are (to be written) from the data to file
 *  @return true if all data was successfully written, false otherwise
 */
bool writeBinaryFile(char *filehandle_in, char *data_in, unsigned int len_in)
{
        bool tmp_result=false;
        char filename[MAXFILENAMELEN];
        char *ptrData=data_in;
        unsigned int written=0;
        unsigned int tmp_int;
        FILE *fp;

        /*trivial pointer checks*/
        assert(filehandle_in);
        assert(data_in);
        

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,filename)) {

                        /*really write data*/
                        if ((fp=fopen(filename,"a")) != NULL) {
                                /*really write data*/
                                while ((tmp_int = fwrite(ptrData,1,len_in,fp)) > 0) {
                                        written += tmp_int;
                                        ptrData += tmp_int;
                                        if (written >= len_in) {
                                                /*we wrote enough*/
                                                tmp_result=true;
                                                break;
                                        } else {
                                                /*we try another round...*/
                                        }
                                }

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("writeBinaryFile");
                        }
                }
        }

        return(tmp_result);
}

/**
 *  Write a string (null terminated) to a file.
 *
 *  @param filehandle_in c-string with filehandle
 *  @param data_in pointer to c-string to write
 *  @return true if all data was successfully written, false otherwise
 */
bool writeTextFile(char *filehandle_in, char *data_in)
{
        bool tmp_result=false;
        char filename[MAXFILENAMELEN];
        FILE *fp;

        /*trivial pointer checks*/
        assert(filehandle_in);
        assert(data_in);


        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,filename)) {

                        /*really write data*/
                        if ((fp=fopen(filename,"a")) != NULL) {
                                /*really write data*/
                                if (fputs(data_in,fp) >= 0) {
                                        tmp_result=true;
                                } else {
                                        PRINTQAERROR("writeTextFile");
                                }

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("writeTextFile");
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Read text from file.
 *
 *  Note that data_out must be big enough.
 *  @param filehandle_in c-string with filehandle
 *  @param data_out pointer to char array (with enough space!!)
 *  @param sizeread_out number of bytes read and/or written to data_out
 *  @return true if all data was successfully read, false otherwise
 */
bool readTextFile(char *filehandle_in, char *data_out, unsigned int *sizeread_out)
{
        bool tmp_result=false;
        char filename[MAXFILENAMELEN];
        unsigned int tmp_int;
        unsigned int read_bytes=0;
        char *ptrData=data_out;
        FILE *fp;

        /*trivial pointer checks*/
        assert(filehandle_in);
        assert(data_out);
        assert(sizeread_out);

        *ptrData = '\0';

        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,filename)) {

                        /*really read data*/
                        if ((fp=fopen(filename,"r")) != NULL) {
        
                                /*really read data*/
                                while ((tmp_int=fread(ptrData,1,1,fp)) > 0) {
                                        read_bytes += tmp_int;
                                        ptrData++;
                                }

                                *ptrData = '\0'; /*give trailing \0*/
                                *sizeread_out = read_bytes;

                                if (ferror(fp) != 0) {
                                        /*fread had a reading problem*/
                                        PRINTQAERROR("error while reading");
                                } else {
                                        tmp_result=true;
                                }

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("opening file of handle");
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Read one line from a text file.
 *
 *  @param filehandle_in c-string with filehandle
 *  @param data_out pointer to char array (with enough space for a textline)
 *  @param sizeread_out number of bytes read or also written to data_out
 *  @return true if all data was successfully read, false otherwise
 */
bool readTextlineFile(char *filehandle_in, char *data_out, unsigned int *sizeread_out)
{
        bool tmp_result=false;
        char filename[MAXFILENAMELEN];
        char buffer[DFLTBUFFERSIZE];
        FILE *fp;

        /*trivial pointer checks*/
        assert(filehandle_in);
        assert(data_out);
        assert(sizeread_out);


        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,filename)) {

                        /*really write data*/
                        if ((fp=fopen(filename,"r")) != NULL) {

                                /*really read data*/
                                if (fgets(buffer,sizeof(buffer),fp) != NULL) {
                                        strcpy(data_out,buffer);
                                        *sizeread_out=strlen(buffer);
                                        tmp_result=true;
                                } else {
                                        PRINTQAERROR("error while reading");
                                        *sizeread_out=0;
                                }
                                

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("error on opening file");
                        }
                }
        }

        return(tmp_result);
}


/**
 *  Read data from binary file.
 *
 *  @param filehandle_in c-string with filehandle
 *  @param data_out pointer to char array (with enough space!!)
 *  @param bytestoread_in number of bytes to be read at max
 *  @param sizeread_out number of really read bytes 
 *  @return true if all data was successfully read, false otherwise
 */
bool readBinaryFile(char *filehandle_in, char *data_out, unsigned int bytestoread_in, unsigned int *sizeread_out)
{
        bool tmp_result=false;
        char filename[MAXFILENAMELEN];
        unsigned int tmp_int;
        unsigned int read_bytes=0;
        char *ptrData=data_out;
        FILE *fp;

        /*trivial pointer checks*/
        assert(filehandle_in);
        assert(data_out);


        if (is_storageready(INTERNAL_STORAGE_BASE) || init_handlemanager(INTERNAL_STORAGE_BASE)) {
                if (resolveHandle(INTERNAL_STORAGE_BASE,filehandle_in,filename)) {

                        /*really read data*/
                        if ((fp=fopen(filename,"r")) != NULL) {

                                /*really read data*/
                                while (read_bytes < bytestoread_in && (tmp_int=fread(ptrData,1,1,fp)) > 0) {
                                        read_bytes += tmp_int;
                                        ptrData++;
                                }

                                if (ferror(fp) != 0) {
                                        /*fread had a reading problem*/
                                        PRINTQAERROR("error while reading");
                                        *sizeread_out = read_bytes;
                                } else {
                                        *sizeread_out = read_bytes;
                                        tmp_result=true;
                                }

                                assert(fclose(fp) == 0);
                        } else {
                                PRINTQAERROR("error on opening file");
                        }
                }
        }

        return(tmp_result);
}
