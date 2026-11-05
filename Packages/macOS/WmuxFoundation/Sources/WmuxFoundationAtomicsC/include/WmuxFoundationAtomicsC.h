#ifndef WMUX_FOUNDATION_ATOMICS_C_H
#define WMUX_FOUNDATION_ATOMICS_C_H

#include <stdbool.h>
#include <stdint.h>
#include <stdatomic.h>

typedef struct {
    atomic_bool value;
} WmuxAtomicBooleanStorage;

void WmuxAtomicBooleanInitialize(WmuxAtomicBooleanStorage *storage, bool initialValue);
bool WmuxAtomicBooleanLoadRelaxed(const WmuxAtomicBooleanStorage *storage);
bool WmuxAtomicBooleanLoadAcquire(const WmuxAtomicBooleanStorage *storage);
void WmuxAtomicBooleanStoreRelease(WmuxAtomicBooleanStorage *storage, bool value);
bool WmuxAtomicBooleanCompareExchange(
    WmuxAtomicBooleanStorage *storage,
    bool expected,
    bool desired
);

typedef struct {
    _Atomic(uint64_t) value;
} WmuxAtomicUInt64Storage;

void WmuxAtomicUInt64Initialize(WmuxAtomicUInt64Storage *storage, uint64_t initialValue);
uint64_t WmuxAtomicUInt64LoadRelaxed(const WmuxAtomicUInt64Storage *storage);
void WmuxAtomicUInt64StoreRelaxed(WmuxAtomicUInt64Storage *storage, uint64_t value);
uint64_t WmuxAtomicUInt64IncrementRelaxed(WmuxAtomicUInt64Storage *storage);
uint64_t WmuxAtomicUInt64AdvanceRelaxed(WmuxAtomicUInt64Storage *storage);
bool WmuxAtomicUInt64IncrementIfBelow(
    WmuxAtomicUInt64Storage *storage,
    uint64_t upperBound
);
bool WmuxAtomicUInt64DecrementIfPositive(WmuxAtomicUInt64Storage *storage);

#endif
