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
                .padding(bottom: 1)

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
            .padding(bottom: 1)

            Toggle("Dark mode", isOn: state.darkMode) { [state] newValue in
                state.darkMode = newValue
            }

            Toggle("Notifications", isOn: state.notifications) { [state] newValue in
                state.notifications = newValue
            }
            .padding(bottom: 1)

            Picker("Theme", selection: state.colorIndex, options: [
                "Default", "Ocean", "Forest", "Sunset",
            ]) { [state] newIndex in
                state.colorIndex = newIndex
            }
            .padding(bottom: 1)

            Button("Submit") { [state] in
                let name = state.name.isEmpty ? "Anonymous" : state.name
                state.statusMessage = "Submitted: \(name)"
                state.submitted = true
            }
            .padding(bottom: 1)

            Text(state.statusMessage, style: Style(fg: .green))

            if state.submitted {
                VStack(spacing: 0) {
                    Text("Name: \(state.name.isEmpty ? "Anonymous" : state.name)")
                    Text("Email: \(state.email.isEmpty ? "(none)" : state.email)")
                    Text("Dark mode: \(state.darkMode ? "on" : "off")")
                    Text("Notifications: \(state.notifications ? "on" : "off")")
                    Text("Theme: \(["Default", "Ocean", "Forest", "Sunset"][state.colorIndex])")
                }
                .padding(top: 1)
            }
        }
        .padding(1)
    }
}
