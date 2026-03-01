import TextUI

@main
struct DemoApp: App {
    let state = DemoState()

    var body: some View {
        VStack {
            Text(" TextUI Demo ", style: Style(fg: .white, bg: .blue).bolded())

            TabView {
                TabView.Tab("Form") {
                    FormTab()
                }
                TabView.Tab("Table") {
                    TableTab()
                }
                TabView.Tab("Progress") {
                    ProgressTab()
                }
                TabView.Tab("Log") {
                    LogTab()
                }
                TabView.Tab("Layout") {
                    LayoutTab()
                }
                TabView.Tab("All Views") {
                    ViewsTab()
                }
            }

            CommandBar()
                .foregroundColor(.blue)
        }
        .environmentObject(state)
    }

    var commands: [CommandGroup] {
        [CommandGroup("App") {
            Button("Quit") { Application.quit() }
                .keyboardShortcut("q", modifiers: .control)
            Button("Reset Form") { [state] in
                state.name = ""
                state.email = ""
                state.darkMode = false
                state.notifications = true
                state.statusMessage = "Form reset"
            }
            .keyboardShortcut("r", modifiers: .control)
        }]
    }
}
