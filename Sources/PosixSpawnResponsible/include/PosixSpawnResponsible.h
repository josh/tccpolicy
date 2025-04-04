// https://github.com/llvm/llvm-project/commit/041c7b8

#include <dispatch/dispatch.h>
#include <spawn.h>

errno_t responsibility_spawnattrs_setdisclaim(posix_spawnattr_t *attrs,
                                              bool disclaim);
