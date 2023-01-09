package com.zachklipp.kmpswiftuitest

import androidx.compose.runtime.snapshots.ObserverHandle
import androidx.compose.runtime.snapshots.Snapshot
import kotlinx.atomicfu.atomic
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch

@Suppress("unused")
object SnapshotBridge {

    private var bootstrapped = atomic(false)

    /** Direct pass-through to [Snapshot.observe]. */
    fun <R> observe(readObserver: (Any) -> Unit, block: () -> R): R =
        Snapshot.observe(readObserver = readObserver, block = block)

    /** Ensures the bridge is initialized and then calls [Snapshot.registerApplyObserver]. */
    fun registerApplyObserver(onApplied: (changedObjects: Set<Any>) -> Unit): ObserverHandle {
        bootstrapApply()
        return Snapshot.registerApplyObserver { applied, _ -> onApplied(applied) }
    }

    /**
     * Bootstrap this process to send snapshot apply notifications whenever a global write is
     * detected.
     */
    private fun bootstrapApply() {
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