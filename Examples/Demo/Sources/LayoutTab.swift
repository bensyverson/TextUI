import TextUI

/// A tab demonstrating layout primitives and styling.
struct LayoutTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                Text("Layout Demo", style: .bold)
                Text("")

                HStack(spacing: 2) {
                    VStack {
                        Text("Red Block")
                        Color(.red)
                            .frame(width: 12, height: 3)
                    }
                    .border()

                    VStack {
                        Text("Green Block")
                        Color(.green)
                            .frame(width: 12, height: 3)
                    }
                    .border()

                    VStack {
                        Text("Blue Block")
                        Color(.blue)
                            .frame(width: 12, height: 3)
                    }
                    .border()
                }

                Divider.horizontal

                HStack(spacing: 1) {
                    Text("Left", style: Style(fg: .cyan))
                    Spacer()
                    Text("Center", style: Style(fg: .yellow).bolded())
                    Spacer()
                    Text("Right", style: Style(fg: .magenta))
                }
                .padding(horizontal: 1)

                Divider.horizontal

                VStack {
                    Text("Nested layout with padding and borders", style: .dim)
                    HStack(spacing: 1) {
                        Text("A")
                            .padding(1)
                            .border(.square)
                        Text("B")
                            .padding(1)
                            .border(.square)
                        Text("C")
                            .padding(1)
                            .border(.square)
                    }
                }

                // MARK: - Group

                Text("Group (layout-transparent):", style: .dim)
                HStack(spacing: 2) {
                    Group {
                        Text("One", style: Style(fg: .green))
                        Text("Two", style: Style(fg: .yellow))
                        Text("Three", style: Style(fg: .magenta))
                    }
                }
                .padding(bottom: 2)

                // MARK: - ZStack

                Text("ZStack (overlaid layers):", style: .dim)
                ZStack {
                    Color(.blue)
                        .frame(width: 30, height: 3)
                    Text("Centered on blue", style: Style(fg: .white).bolded())
                }
                .padding(bottom: 2)
            }
            .padding(1)
        } // ScrollView
    }
}
