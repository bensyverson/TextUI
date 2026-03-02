import Foundation
import TextUI

/// A tab demonstrating `@State` and `.task {}` with a live-updating log.
///
/// Every second, a new log entry is appended with a random message
/// from a pool of realistic events. The log is displayed in a
/// ``ScrollView`` so you can scroll through history while new
/// entries continue to appear.
struct LogTab: View {
    @State var entries: [LogEntry] = []

    var body: some View {
        VStack(spacing: 1) {
            Text("Live Log (\(entries.count) entries)", style: .bold)

            ScrollView {
                ForEach(entries) { entry in
                    HStack {
                        Text(entry.formattedIndex, style: Style(fg: .white).dimmed())
                        Text(entry.timestamp, style: Style(fg: .cyan))
                        Text(entry.message)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
        }
        .padding(1)
        .task {
            var counter = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                counter += 1
                let entry = LogEntry(
                    index: counter,
                    timestamp: LogEntry.currentTimestamp(),
                    message: LogEntry.randomMessage(),
                )
                entries.append(entry)
            }
        }
    }

    // MARK: - LogEntry

    struct LogEntry: Friendly, Identifiable {
        let index: Int
        let timestamp: String
        let message: String

        var id: Int {
            index
        }

        /// Zero-padded index for display alignment.
        var formattedIndex: String {
            String(format: "#%03d", index)
        }

        /// Returns the current time as HH:MM:SS.
        static func currentTimestamp() -> String {
            let now = Date()
            let calendar = Calendar.current
            let h: Int = calendar.component(Calendar.Component.hour, from: now)
            let m: Int = calendar.component(Calendar.Component.minute, from: now)
            let s: Int = calendar.component(Calendar.Component.second, from: now)
            return String(format: "%02d:%02d:%02d", h, m, s)
        }

        /// Returns a random log message from a pool of realistic entries.
        static func randomMessage() -> String {
            messages.randomElement()!
        }

        private static let messages = [
            "Connection established to db-primary",
            "Cache hit for session token (TTL 3600s)",
            "Request completed: GET /api/users (200, 42ms)",
            "Worker pool scaled to 4 threads",
            "Heartbeat received from node-02",
            "Config reloaded: 12 keys updated",
            "Rate limiter reset for 10.0.0.1",
            "TLS handshake completed (TLS 1.3)",
            "Scheduled job 'cleanup' started",
            "Index rebuilt: 1,284 documents in 380ms",
            "WebSocket client connected (id: 7f3a)",
            "Metrics flushed: 847 data points",
        ]
    }
}
