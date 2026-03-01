import TextUI

@main
struct DemoApp: App {
    let theme = ThemeState()

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
        .environmentObject(theme)
    }

    var commands: [CommandGroup] {
        [CommandGroup("App") {
            Button("Quit") { Application.quit() }
                .keyboardShortcut("q", modifiers: .control)
        }]
    }
}
