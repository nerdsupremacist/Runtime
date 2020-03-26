
#ifndef csymbols_h
#define csymbols_h

#ifdef __linux__
#define _GNU_SOURCE
#endif

#include <stddef.h>
#include <dlfcn.h>

typedef struct SymbolInfo {
    const char* name;
    void* address;
} symbolInfo;

void loadSymbol(const void *address, symbolInfo *symbol) {
    Dl_info info;
    dladdr(address, &info);
    symbol->name = info.dli_sname;
    symbol->address = info.dli_saddr;
}

void *loadAddressForSymbol(const char *symbolName) {
    void *handle = dlopen(NULL, RTLD_GLOBAL);
    return dlsym(handle, symbolName);
}

#endif
