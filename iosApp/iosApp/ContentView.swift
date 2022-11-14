import SwiftUI
import shared

struct ContentView: View {
    @ObservedObject var greeting: SnapshotStateObservableObject<Greeting>

    init(greeting: Greeting) {
        self.greeting = SnapshotStateObservableObject(greeting)
    }

	var body: some View {
        VStack{
            Text(greeting.greeting)
            Text("Salutation: \(greeting.salutation)")
            TextField(text: $greeting.salutation, label: { Text("Salutation") })
            Text("Name: \(greeting.name)")
            TextField(text: $greeting.name, label: { Text("Name") })
            Button {
                withAnimation {
                    greeting.wrappedObject.reset()
                }
            } label: {
                Text("Reset")
            }
        }
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
        ContentView(greeting: Greeting())
	}
}
