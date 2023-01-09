import SwiftUI
import shared

struct ContentView: View {
    let greeting: Greeting

	var body: some View {
        ComposeStateObserver {
            VStack {
                Text(greeting.greeting)
                Text("Salutation: \(greeting.salutation)")
                TextField(text: bindingFor(greeting, \.salutation), label: { Text("Salutation") })
                Text("Name: \(greeting.name)")
                TextField(text: bindingFor(greeting, \.name), label: { Text("Name") })
                Button {
                    withAnimation {
                        greeting.reset()
                    }
                } label: {
                    Text("Reset")
                }
            }
        }
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
        ContentView(greeting: Greeting())
	}
}
