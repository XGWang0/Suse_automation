/*
 * libqainterl:handlemanager.h
 * Copyright ?
 * Description: external deklarations of handlemanager..
 */

#include <stdbool.h>

#include "global.h"


#ifndef LIBQAINTERNAL_HANDLEMANAGER_H
#define LIBQAINTERNAL_HANDLEMANAGER_H

/* Helper functions (handlemanager) - not part of the API.
  * @file handlemanager.c  
  */

extern bool init_handlemanager(char *storage_base);
extern bool is_storageready(char *storage_base);
extern bool is_storagelocked(char *storage_base);
extern bool lock_storage(char *storage_base);
extern bool unlock_storage(char *storage_base);
extern bool createHandle(char *storage_base,char *type, char *content, char *handle_out);
extern bool resolveHandle(char *storage_base,char *handle_in,char *content_out);
extern bool deleteHandle(char *storage_base,char *handle_in);
extern const char *get_handleprefix(char * type);

#endif
