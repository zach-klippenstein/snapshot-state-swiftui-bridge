import SwiftUI
import shared

@main
struct iOSApp: App {
    @State private var greeting = Greeting()
    
	var body: some Scene {
		WindowGroup {
            ContentView(greeting: greeting)
		}
	}
}
