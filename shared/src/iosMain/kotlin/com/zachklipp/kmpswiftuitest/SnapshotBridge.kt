package com.zachklipp.kmpswiftuitest

import androidx.compose.runtime.snapshots.Snapshot
import kotlinx.atomicfu.atomic
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch

object SnapshotBridge {

    private var bootstrapped = atomic(false)

    /**
     * Bootstrap this process to send snapshot apply notifications whenever a global write is
     * detected.
     */
    fun bootstrapApply() {
        if (!bootstrapped.compareAndSet(expect = false, update = true)) return

        val applyChannel = Channel<Unit>(capacity = Channel.CONFLATED)
        val scope = CoroutineScope(Dispatchers.Unconfined) // TODO why doesn't Main work?

        scope.launch {
            for (unit in applyChannel) {
                Snapshot.sendApplyNotifications()
            }
        }

        Snapshot.registerGlobalWriteObserver {
            applyChannel.trySend(Unit)
        }
    }
}