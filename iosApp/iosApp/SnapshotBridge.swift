import SwiftUI
import Combine
import shared

func bootstrapSnapshotBridge() {
    SnapshotBridge.shared.bootstrapApply()
}

//extension StateObject<T> where ObjectType == SnapshotStateObservableObject<Any> {
//    init<T: KotlinBase>(fromKotlin snapshotStateObject: T) {
//        self.init(wrappedValue: SnapshotStateObservableObject(snapshotStateObject))
//    }
//}

//@propertyWrapper
//struct SnapshotStateObservedObject<Value: KotlinBase> {
//    @ObservedObject var wrappedValue: SnapshotStateObservableObject<Value>
//    
//    init(_ observableValue: SnapshotStateObservableObject<Value>) {
//        self.wrappedValue = observableValue
//    }
//    
//    init(_ value: Value) {
//        self.wrappedValue = SnapshotStateObservableObject(value)
//    }
//}

@dynamicMemberLookup
class SnapshotStateObservableObject<SnapshotStateType: KotlinBase>: ObservableObject {
    private let snapshotStateObject: SnapshotStateType
    private let helper = ChangeTrackingHelper()
    
    var wrappedObject: SnapshotStateType {
        get { snapshotStateObject }
    }
    
    init(_ stateObject: SnapshotStateType) {
        self.snapshotStateObject = stateObject
    }

    lazy var objectWillChange = SnapshotStateObjectWillChangePublisher(delegate: helper)
    
    subscript<T>(dynamicMember keyPath: KeyPath<SnapshotStateType, T>) -> T{
        helper.observeReadsForKey(key: keyPath) {
            self.snapshotStateObject[keyPath: keyPath]
        } as! T
    }
    
    subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<SnapshotStateType, T>) -> T {
        get {
            helper.observeReadsForKey(key: keyPath) {
                self.snapshotStateObject[keyPath: keyPath]
            } as! T
        }
        set {
            snapshotStateObject[keyPath: keyPath] = newValue
            
        }
    }
}

public struct SnapshotStateObjectWillChangePublisher: Publisher {
    
    public typealias Failure = Never
    public typealias Output = Void

    let delegate: ChangeTrackingHelper
    
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        let subscription = SnapshotStateWillChangeSubscription<S>()
        subscription.target = subscriber

        subscriber.receive(subscription: subscription)

        subscription.onCancel = delegate.registerChangedObserver {
            subscription.trigger()
        }
    }
}

public struct SwiftObservableObjectWillChange: Publisher {

    public typealias Failure = Never
    public typealias Output = Void

    let delegate: SwiftObservableObject

    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        let subscription = SnapshotStateWillChangeSubscription<S>()
        subscription.target = subscriber

        subscriber.receive(subscription: subscription)

        subscription.onCancel = delegate.registerWillChangeObserver {
            subscription.trigger()
        }
    }
}

class SnapshotStateWillChangeSubscription<Target: Subscriber> : Subscription where Target.Input == Void {

    var target: Target?
    var onCancel: (() -> Void)?

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        target = nil
        onCancel?.self()
    }

    func trigger() {
        target?.receive(())
    }
}
