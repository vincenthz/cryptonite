#ifndef CRYPTOHASH_ARGON2_H
#define CRYPTOHASH_ARGON2_H

#include "argon2.h"

int cryptonite_argon2_hash_haskell(const uint32_t t_cost, const uint32_t m_cost,
                                   const uint32_t parallelism, const void *pwd,
                                   const size_t pwdlen, const void *salt,
                                   const size_t saltlen, void *hash,
                                   const size_t hashlen, argon2_type type,
                                   const uint32_t version);

#endif
