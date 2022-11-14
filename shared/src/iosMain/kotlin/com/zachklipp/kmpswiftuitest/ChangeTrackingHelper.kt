package com.zachklipp.kmpswiftuitest

import androidx.compose.runtime.snapshots.Snapshot
import kotlinx.atomicfu.locks.withLock

class ChangeTrackingHelper {

    private val lock = kotlinx.atomicfu.locks.reentrantLock()
    private val readObjects = mutableMapOf<Any, MutableSet<Any>>()

    fun <R> observeReadsForKey(key: Any, block: () -> R): R {
        val readObjects = mutableSetOf<Any>()
        lock.withLock {
            this.readObjects[key] = readObjects
        }
        return Snapshot.observe(readObserver = { readObjects += it }, block = block)
    }

    fun registerChangedObserver(onChanged: () -> Unit): () -> Unit {
        val handle = Snapshot.registerApplyObserver { applied, _ ->
            val didChange = lock.withLock {
                readObjects.any { it.value.any { it in applied } }
            }
            // Invoke callback out of critical section.
            if (didChange) {
                onChanged()
            }
        }
        return handle::dispose
    }
}