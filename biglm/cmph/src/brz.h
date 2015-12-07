#ifndef __CMPH_BRZ_H__
#define __CMPH_BRZ_H__

#include "cmph.h"

#ifdef __cplusplus
#pragma message("HOW DO I TURN OFF THIS FSCKING C++ COMPILER!?!")
#else
#pragma message("I AM COMPILING IN C!")
#endif

typedef struct __brz_data_t brz_data_t;
typedef struct __brz_config_data_t brz_config_data_t;

brz_config_data_t *brz_config_new();
void brz_config_set_hashfuncs(cmph_config_t *mph, CMPH_HASH *hashfuncs);
void brz_config_set_tmp_dir(cmph_config_t *mph, cmph_uint8 *tmp_dir);
void brz_config_set_mphf_fd(cmph_config_t *mph, FILE *mphf_fd);
void brz_config_set_b(cmph_config_t *mph, cmph_uint8 b);
void brz_config_set_algo(cmph_config_t *mph, CMPH_ALGO algo);
void brz_config_set_memory_availability(cmph_config_t *mph, cmph_uint32 memory_availability);
void brz_config_destroy(cmph_config_t *mph);
cmph_t *brz_new(cmph_config_t *mph, float c);

void brz_load(FILE *f, cmph_t *mphf);
int brz_dump(cmph_t *mphf, FILE *f);
void brz_destroy(cmph_t *mphf);
cmph_uint32 brz_search(cmph_t *mphf, const char *key, cmph_uint32 keylen);
#endif
