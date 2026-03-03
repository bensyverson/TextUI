import TextUI

@main
struct HelloApp: App {
    @State var name: String = ""
    @State var showAbout: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            Spacer()
            VStack(spacing: 1) {
                HStack {
                    Text("Name: ")
                    TextField("Enter your name", text: name) { newValue in
                        name = newValue
                    }
                }

                if showAbout {
                    if name != "" {
                        Text("Hello, \(name)!")
                            .foregroundColor(.brightGreen)
                    }
                    Text("This is a demo of a TextUI app. TextUI allows you to compose expressive terminal UIs and apps using a declarative syntax which mirrors SwiftUI.")
                        .italic()
                        .foregroundColor(.green)
                }

                HStack(spacing: 1) {
                    Spacer()
                    Button("About") {
                        showAbout.toggle()
                    }.keyboardShortcut("a", modifiers: .control)

                    Button("Quit") {
                        Application.quit()
                    }.keyboardShortcut("q", modifiers: .control)
                        .foregroundColor(.red)
                }
            }.frame(maxWidth: 45)
                .padding(1)
                .border()
                .buttonStyle(.bordered)

            Spacer()
        }
    }
}
