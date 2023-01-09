import SwiftUI
import shared

/// Helper to generate bindings for properties of Kotlin objects.
func bindingFor<S: KotlinBase, T>(_ object: S, _ keyPath: ReferenceWritableKeyPath<S, T>) -> Binding<T> {
    return Binding(
        get: { object[keyPath: keyPath] },
        set: { object[keyPath: keyPath] = $0 }
    )
}
