import TextUI

/// A tab demonstrating TextField, Toggle, Button, and focus navigation.
struct FormTab: View {
    @EnvironmentObject var state: DemoState

    enum Field: Hashable, Sendable {
        case name
        case email
    }

    @FocusState var focus: Field?

    var body: some View {
        VStack(spacing: 1) {
            Text("User Profile", style: .bold)
            Text("")

            HStack(spacing: 1) {
                Text("Name:  ", style: .dim)
                TextField("Enter your name", text: state.name) { [state] newValue in
                    state.name = newValue
                }
                .focused($focus, equals: .name)
            }

            HStack(spacing: 1) {
                Text("Email: ", style: .dim)
                TextField("user@example.com", text: state.email) { [state] newValue in
                    state.email = newValue
                }
                .focused($focus, equals: .email)
            }

            Text("")

            Toggle("Dark mode", isOn: state.darkMode) { [state] newValue in
                state.darkMode = newValue
            }

            Toggle("Notifications", isOn: state.notifications) { [state] newValue in
                state.notifications = newValue
            }

            Text("")

            Picker("Theme", selection: state.colorIndex, options: [
                "Default", "Ocean", "Forest", "Sunset",
            ]) { [state] newIndex in
                state.colorIndex = newIndex
            }

            Text("")

            Button("Submit") { [state] in
                let name = state.name.isEmpty ? "Anonymous" : state.name
                state.statusMessage = "Submitted: \(name)"
            }

            Text("")
            Text(state.statusMessage, style: Style(fg: .green))
        }
        .padding(1)
    }
}
