import TextUI

/// A tab demonstrating TextField, Toggle, Button, and focus navigation.
struct FormTab: View {
    @State var name: String = ""
    @State var email: String = ""
    @State var darkMode: Bool = false
    @State var notifications: Bool = true
    @State var colorIndex: Int = 0
    @State var statusMessage: String = "Ready"
    @State var submitted: Bool = false

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
                TextField("Enter your name", text: name) { newValue in
                    name = newValue
                }
                .focused($focus, equals: .name)
            }

            HStack(spacing: 1) {
                Text("Email: ", style: .dim)
                TextField("user@example.com", text: email) { newValue in
                    email = newValue
                }
                .focused($focus, equals: .email)
            }
            .padding(bottom: 1)

            Toggle("Dark mode", isOn: darkMode) { newValue in
                darkMode = newValue
            }

            Toggle("Notifications", isOn: notifications) { newValue in
                notifications = newValue
            }
            .padding(bottom: 1)

            Picker("Theme", selection: colorIndex, options: [
                "Default", "Ocean", "Forest", "Sunset",
            ]) { newIndex in
                colorIndex = newIndex
            }
            .padding(bottom: 1)

            Button("Submit") {
                let displayName = name.isEmpty ? "Anonymous" : name
                statusMessage = "Submitted: \(displayName)"
                submitted = true
            }
            .padding(bottom: 1)

            Text(statusMessage, style: Style(fg: .green))

            if submitted {
                VStack(spacing: 0) {
                    Text("Name: \(name.isEmpty ? "Anonymous" : name)")
                    Text("Email: \(email.isEmpty ? "(none)" : email)")
                    Text("Dark mode: \(darkMode ? "on" : "off")")
                    Text("Notifications: \(notifications ? "on" : "off")")
                    Text("Theme: \(["Default", "Ocean", "Forest", "Sunset"][colorIndex])")
                }
                .padding(top: 1)
            }
        }
        .padding(1)
    }
}
