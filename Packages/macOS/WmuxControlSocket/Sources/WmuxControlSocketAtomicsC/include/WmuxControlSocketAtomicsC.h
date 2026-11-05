#ifndef WMUX_CONTROL_SOCKET_ATOMICS_C_H
#define WMUX_CONTROL_SOCKET_ATOMICS_C_H

#include <stdint.h>
#include <stdatomic.h>

typedef struct {
    _Atomic(uintptr_t) value;
} WmuxControlSocketAtomicPointerStorage;

void WmuxControlSocketAtomicPointerInitialize(
    WmuxControlSocketAtomicPointerStorage *storage,
    uintptr_t initialValue
);
uintptr_t WmuxControlSocketAtomicPointerLoadAcquire(
    const WmuxControlSocketAtomicPointerStorage *storage
);
uintptr_t WmuxControlSocketAtomicPointerExchange(
    WmuxControlSocketAtomicPointerStorage *storage,
    uintptr_t value
);

typedef struct {
    _Atomic(uint64_t) value;
} WmuxControlSocketAtomicCounterStorage;

void WmuxControlSocketAtomicCounterInitialize(
    WmuxControlSocketAtomicCounterStorage *storage,
    uint64_t initialValue
);
uint64_t WmuxControlSocketAtomicCounterLoad(
    const WmuxControlSocketAtomicCounterStorage *storage
);
void WmuxControlSocketAtomicCounterIncrement(
    WmuxControlSocketAtomicCounterStorage *storage
);
void WmuxControlSocketAtomicCounterDecrement(
    WmuxControlSocketAtomicCounterStorage *storage
);

#endif
