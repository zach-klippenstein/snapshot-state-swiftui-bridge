import SwiftUI
import Combine
import shared

/// A SwiftUI container that will rerender its content whenever any Compose (snapshot) state it reads is changed.
///
/// When this view is rendered, it tracks which snapshot state objects were read by ``content``. When any of
/// those state objects are changed the view will automatically refresh. This view effectively performs the functionality
/// that Compose automatically inserts into each restartable composable function.
///
/// ## Example
///
/// Given this model class defined in Kotlin:
/// ```kotlin
/// class Counter {
///     var value by mutableStateOf(0)
///         private set
///
///     fun increment() {
///         value++
///     }
/// }
/// ```
///
/// A SwiftUi view could consume it like this:
/// ```swift
/// struct App: View {
///     @StateObject var counter = Counter()
///
///     var body: some View {
///         ComposeStateObserver {
///             Button {
///                 counter.increment()
///             } label: {
///                 Text("Counter: \(counter.value)")
///             }
///         }
///     }
/// }
/// ```
struct ComposeStateObserver<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @StateObject private var helper = SnapshotObserver()

    var body: Content {
        helper.recordReads(in: content)
    }
}

/// Tracks any snapshot state objects read inside the block passed to ``recordReads``, then notifies any
/// ``Subscriber``s when any of those objects are changed.
private class SnapshotObserver: ObservableObject, Publisher {
    
    typealias Output = Void
    typealias Failure = Never

    private var readStateObjects: Set<AnyHashable> = []
    
    var objectWillChange: SnapshotObserver { self }
    
    /// Runs ``block`` and records all snapshot state objects read inside of it.
    ///
    /// After this method returns, this publisher will only emit when the last-recorded set of objects is changed.
    func recordReads<R>(in block: @escaping () -> R) -> R {
        debugPrint("SnapshotObserver recording reads…")
        defer {
            debugPrint("SnapshotObserver finished recording reads")
        }
        
        // Record into a new set so we can atomically swap it in when finished
        // recording reads.
        var newlyReadObjects: Set<AnyHashable> = []
        defer { self.readStateObjects = newlyReadObjects } // TODO write this in a lock?

        return SnapshotBridge.shared.observe(
            // All objects will be Kotlin objects, and all Kotlin objects are hashable.
            readObserver: { newlyReadObjects.insert($0 as! AnyHashable) },
            block: block
        ) as! R
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        let subscription = SubjectSubscription<S>()
        subscription.target = subscriber
        subscriber.receive(subscription: subscription)
        
        debugPrint("SnapshotObserver registering change observer…")
        // We could try harder to ensure we only register one apply observer, but this class is only
        // used internally and so we know it will never be subscribed to in more than one place.
        let handle = SnapshotBridge.shared.registerApplyObserver { changedObjects in
            // Read the property once for consistency, since we're going to access it multiple times below.
            let readObjects = self.readStateObjects // TODO read this in a lock?
            // The callback gets invoked anytime _anything_ changes. But we only want to trigger an
            // update when a state object we read is changed.
            if changedObjects.contains(where: { readObjects.contains($0) }) {
                debugPrint("SnapshotObserver got change notification!")
                subscription.send()
            }
        }
        subscription.onCancel = handle.dispose
    }
}

/// A very basic ``Subscription`` that sends ``Void`` to subscribers and accepts a cancellation handler.
private class SubjectSubscription<Target: Subscriber> : Subscription where Target.Input == Void {

    var target: Target?
    var onCancel: (() -> Void)?

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        target = nil
        onCancel?.self()
    }

    func send() {
        target?.receive(())
    }
}
