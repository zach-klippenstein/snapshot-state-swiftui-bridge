package com.zachklipp.kmpswiftuitest

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.Snapshot

abstract class SwiftObservableObject {
    abstract fun registerWillChangeObserver(block: () -> Unit): () -> Unit
}

class Greeting : SwiftObservableObject() {
    private val platform: Platform = getPlatform()

    private val _salutation = mutableStateOf("Hello")
    var salutation by _salutation

    private val _name = mutableStateOf(platform.name)
    var name by _name

    val greeting: String get() = "$salutation, $name!"

    fun reset() {
        salutation = "Hello"
        name = platform.name
    }

    /** For iOS */
    override fun registerWillChangeObserver(block: () -> Unit): () -> Unit {
        val handle = Snapshot.registerApplyObserver { applied, _ ->
            if (_salutation in applied || _name in applied) {
                block()
            }
        }
        return handle::dispose
    }
}