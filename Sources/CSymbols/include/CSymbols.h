
#ifndef csymbols_h
#define csymbols_h

typedef struct SymbolInfo {
    const char *name;
    void *address;
} symbolInfo;

void loadSymbol(const void *address, symbolInfo *symbol);

void *loadAddressForSymbol(const char *symbolName);

#endif
