
#ifdef __linux__
#define _GNU_SOURCE
#endif

#include <CSymbols.h>
#include <stddef.h>
#include <dlfcn.h>

void loadSymbol(const void *address, symbolInfo *symbol) {
    Dl_info info;
    symbolInfo newSymbol;
    dladdr(address, &info);
    if (info.dli_sname) {
        newSymbol.name = info.dli_sname;
    }
    if (info.dli_saddr) {
        newSymbol.address = info.dli_saddr;
    }
    *symbol = newSymbol;
}

void *loadAddressForSymbol(const char *symbolName) {
    void *handle = dlopen(NULL, RTLD_GLOBAL);
    return dlsym(handle, symbolName);
}
