#ifndef CRESOLV_H
#define CRESOLV_H

#include <sys/types.h>

// Thin wrappers around libresolv functions (which are macros on macOS,
// so they can't be imported directly into Swift).
int cresolv_query(const char *dname, int class_field, int type,
                  unsigned char *answer, int anslen);
int cresolv_dn_expand(const unsigned char *msg, const unsigned char *eom,
                      const unsigned char *src, char *dst, int dstsiz);

#endif
