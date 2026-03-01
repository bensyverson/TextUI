import TextUI

/// A tab demonstrating Table and ScrollView with sample process data.
struct TableTab: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("Process List (ScrollView + Table)", style: .bold)
                .padding(bottom: 1)

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
            ProcessInfo(pid: "78", name: "logd", cpu: "0.2", memory: "8.1 MB"),
            ProcessInfo(pid: "142", name: "WindowServer", cpu: "8.3", memory: "256.1 MB"),
            ProcessInfo(pid: "198", name: "sysmond", cpu: "0.4", memory: "15.7 MB"),
            ProcessInfo(pid: "234", name: "corebrightnessd", cpu: "0.0", memory: "4.2 MB"),
            ProcessInfo(pid: "287", name: "Finder", cpu: "1.2", memory: "89.7 MB"),
            ProcessInfo(pid: "312", name: "Dock", cpu: "0.5", memory: "45.2 MB"),
            ProcessInfo(pid: "345", name: "SystemUIServer", cpu: "0.3", memory: "32.6 MB"),
            ProcessInfo(pid: "401", name: "Spotlight", cpu: "3.6", memory: "78.9 MB"),
            ProcessInfo(pid: "456", name: "iTerm2", cpu: "2.1", memory: "167.3 MB"),
            ProcessInfo(pid: "512", name: "dataaccessd", cpu: "0.1", memory: "11.3 MB"),
            ProcessInfo(pid: "589", name: "swift", cpu: "45.7", memory: "512.8 MB"),
            ProcessInfo(pid: "623", name: "Safari", cpu: "12.4", memory: "1.2 GB"),
            ProcessInfo(pid: "641", name: "WebContent", cpu: "7.8", memory: "345.2 MB"),
            ProcessInfo(pid: "658", name: "WebContent", cpu: "4.2", memory: "289.1 MB"),
            ProcessInfo(pid: "672", name: "WebContent", cpu: "1.1", memory: "198.4 MB"),
            ProcessInfo(pid: "701", name: "Mail", cpu: "0.8", memory: "102.5 MB"),
            ProcessInfo(pid: "745", name: "Xcode", cpu: "15.3", memory: "892.4 MB"),
            ProcessInfo(pid: "812", name: "redis-server", cpu: "0.6", memory: "22.1 MB"),
            ProcessInfo(pid: "867", name: "Granola", cpu: "1.4", memory: "58.3 MB"),
            ProcessInfo(pid: "912", name: "countryd", cpu: "0.0", memory: "6.8 MB"),
            ProcessInfo(pid: "934", name: "reversetemplated", cpu: "0.0", memory: "3.9 MB"),
            ProcessInfo(pid: "978", name: "ImageIOXPCService", cpu: "0.3", memory: "14.5 MB"),
            ProcessInfo(pid: "1024", name: "Activity Monitor", cpu: "1.9", memory: "55.4 MB"),
            ProcessInfo(pid: "1089", name: "Notes", cpu: "0.7", memory: "73.8 MB"),
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
