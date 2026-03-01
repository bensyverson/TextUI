import TextUI

/// A tab demonstrating Table and ScrollView with sample process data.
struct TableTab: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("Process List (ScrollView + Table)", style: .bold)
            Text("")

            ScrollView {
                Table(
                    rows: processes.map { process in
                        [
                            Text(process.pid),
                            Text(process.name),
                            Text(process.cpu, style: Style(fg: process.cpuColor)),
                            Text(process.memory),
                        ] as [any View]
                    },
                ) {
                    Table.Column.fixed("PID", width: 8)
                    Table.Column.flex("Name")
                    Table.Column.fixed("CPU%", width: 8)
                    Table.Column.fixed("Memory", width: 10)
                }
            }
        }
        .padding(1)
    }

    private var processes: [ProcessInfo] {
        [
            ProcessInfo(pid: "1", name: "launchd", cpu: "0.1", memory: "12.4 MB"),
            ProcessInfo(pid: "142", name: "WindowServer", cpu: "8.3", memory: "256.1 MB"),
            ProcessInfo(pid: "287", name: "Finder", cpu: "1.2", memory: "89.7 MB"),
            ProcessInfo(pid: "312", name: "Dock", cpu: "0.5", memory: "45.2 MB"),
            ProcessInfo(pid: "456", name: "Terminal", cpu: "2.1", memory: "67.3 MB"),
            ProcessInfo(pid: "589", name: "swift", cpu: "45.7", memory: "512.8 MB"),
            ProcessInfo(pid: "623", name: "Safari", cpu: "12.4", memory: "1.2 GB"),
            ProcessInfo(pid: "701", name: "Mail", cpu: "0.8", memory: "102.5 MB"),
            ProcessInfo(pid: "845", name: "Spotlight", cpu: "3.6", memory: "78.9 MB"),
            ProcessInfo(pid: "912", name: "Activity Mon", cpu: "1.9", memory: "55.4 MB"),
        ]
    }

    struct ProcessInfo {
        let pid: String
        let name: String
        let cpu: String
        let memory: String

        var cpuColor: Style.Color {
            guard let value = Double(cpu) else { return .white }
            if value > 10 { return .red }
            if value > 5 { return .yellow }
            return .green
        }
    }
}
