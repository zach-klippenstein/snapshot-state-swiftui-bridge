# snapshot-state-swiftui-bridge

Simple library for observing Jetpack Compose's snapshot state in your SwiftUI views.

## Usage

Put `SnapshotBridge.kt` into your Kotlin iOS source set, `ComposeStateObserver.swift` into your
Swift codebase that consumes your Kotlin code, and then just call `ComposeStateObserver` from your
SwiftUI views. Any snapshot state objects read in the closure passed to `ComposeStateObserver` will
be tracked and the body of the `ComposeStateObserver` will re-render when those objects are changed.

All the usual rules about snapshot state read tracking apply: the reads can happen at any depth in
the call stack.

## Example

Given this model class defined in Kotlin:

```kotlin
class Counter {
    var value by mutableStateOf(0)
        private set

    fun increment() {
        value++
    }
}
```

A SwiftUi view could consume it like this:

```swift
struct App: View {
    @StateObject var counter = Counter()

    var body: some View {
        ComposeStateObserver {
            Button {
                counter.increment()
            } label: {
                Text("Counter: \(counter.value)")
            }
        }
    }
}
```

See the swiftdoc on `ComposeStateObserver` for more information.

## Related links

- [Design doc](https://docs.google.com/document/d/1mefy54LJFRIH73Aw7V_R9Xm2GmEGeyJ_FRjtXffYU38)
- [Mastodon thread](https://androiddev.social/@zachklipp/109326781860500334)
