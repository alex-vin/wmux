#include "WmuxControlSocketAtomicsC.h"

void WmuxControlSocketAtomicPointerInitialize(
    WmuxControlSocketAtomicPointerStorage *storage,
    uintptr_t initialValue
) {
    atomic_init(&storage->value, initialValue);
}

uintptr_t WmuxControlSocketAtomicPointerLoadAcquire(
    const WmuxControlSocketAtomicPointerStorage *storage
) {
    return atomic_load_explicit(&storage->value, memory_order_seq_cst);
}

uintptr_t WmuxControlSocketAtomicPointerExchange(
    WmuxControlSocketAtomicPointerStorage *storage,
    uintptr_t value
) {
    return atomic_exchange_explicit(&storage->value, value, memory_order_seq_cst);
}

void WmuxControlSocketAtomicCounterInitialize(
    WmuxControlSocketAtomicCounterStorage *storage,
    uint64_t initialValue
) {
    atomic_init(&storage->value, initialValue);
}

uint64_t WmuxControlSocketAtomicCounterLoad(
    const WmuxControlSocketAtomicCounterStorage *storage
) {
    return atomic_load_explicit(&storage->value, memory_order_seq_cst);
}

void WmuxControlSocketAtomicCounterIncrement(
    WmuxControlSocketAtomicCounterStorage *storage
) {
    atomic_fetch_add_explicit(&storage->value, 1, memory_order_seq_cst);
}

void WmuxControlSocketAtomicCounterDecrement(
    WmuxControlSocketAtomicCounterStorage *storage
) {
    atomic_fetch_sub_explicit(&storage->value, 1, memory_order_seq_cst);
}
