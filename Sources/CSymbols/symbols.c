
#ifdef __linux__
#define _GNU_SOURCE
#endif

#include <CSymbols.h>
#include <stddef.h>
#include <dlfcn.h>
#include <stdint.h>

void loadSymbol(const void *address, symbolInfo *symbol) {
    Dl_info info;
    dladdr(address, &info);
    uintptr_t pointerValue = (uintptr_t)info.dli_sname;
    if (info.dli_sname && pointerValue > 0xff) {
        symbol->name = info.dli_sname;
    }
    if (info.dli_saddr) {
        symbol->address = info.dli_saddr;
    }
}

void *loadAddressForSymbol(const char *symbolName) {
    void *handle = dlopen(NULL, RTLD_GLOBAL);
    return dlsym(handle, symbolName);
}
