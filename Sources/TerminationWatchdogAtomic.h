#ifndef WMUX_TERMINATION_WATCHDOG_ATOMIC_H
#define WMUX_TERMINATION_WATCHDOG_ATOMIC_H

#include <stdbool.h>
#include <stdatomic.h>

typedef struct {
    atomic_bool isArmed;
} WMUXTerminationWatchdogLatch;

WMUXTerminationWatchdogLatch WMUXTerminationWatchdogLatchMake(void);
bool WMUXTerminationWatchdogLatchClaim(WMUXTerminationWatchdogLatch *latch);

#endif
