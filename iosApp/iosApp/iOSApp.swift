import SwiftUI
import shared

@main
struct iOSApp: App {
    @StateObject private var greeting = SnapshotStateObservableObject(Greeting())
    
    init() {
        bootstrapSnapshotBridge()
    }
    
	var body: some Scene {
		WindowGroup {
            ContentView(greeting: greeting.wrappedObject)
		}
	}
}
