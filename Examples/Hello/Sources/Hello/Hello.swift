import TextUI

@main
struct HelloApp: App {
    @State var name: String = ""

    var body: some View {
        VStack(spacing: 1) {
            TextField("Enter your name", text: name) { newValue in
                name = newValue
            }
            Button("Quit") { Application.quit() }
                .keyboardShortcut("q", modifiers: .control)

            CommandBar()
        }.buttonStyle(.bordered)
            .padding(1)
            .border()
    }
}
