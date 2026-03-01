#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif
import Foundation

/// Low-level terminal control: raw mode, alternate screen, cursor, and size queries.
///
/// `Terminal` provides static methods for controlling the terminal. It manages
/// raw mode (disabling line buffering and echo), the alternate screen buffer,
/// cursor visibility, and terminal size queries.
///
/// This type is not instantiated — all functionality is accessed through
/// static methods.
public enum Terminal {
    /// Terminal dimensions in columns and rows.
    public struct Size: Friendly {
        /// The number of columns (horizontal character positions).
        public var width: Int

        /// The number of rows (vertical character positions).
        public var height: Int

        /// Creates a terminal size with the given dimensions.
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
    }

    // MARK: - Size

    /// Queries the current terminal size via ioctl.
    public static func size() -> Size {
        var ws = winsize()
        _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws)
        return Size(width: Int(ws.ws_col), height: Int(ws.ws_row))
    }

    // MARK: - Raw Mode

    private nonisolated(unsafe) static var originalTermios: termios?

    /// Enables raw mode on stdin.
    ///
    /// Saves the original terminal state for later restoration via
    /// ``disableRawMode()``. In raw mode, input is unbuffered, echo
    /// is disabled, and signal processing is turned off.
    public static func enableRawMode() {
        var raw = termios()
        tcgetattr(STDIN_FILENO, &raw)
        originalTermios = raw

        // Disable canonical mode, echo, signals, and input processing
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)
        raw.c_iflag &= ~tcflag_t(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        raw.c_oflag &= ~tcflag_t(OPOST)
        raw.c_cflag |= tcflag_t(CS8)

        // VMIN/VTIME: read returns immediately with at least 1 byte
        #if canImport(Darwin)
            raw.c_cc.16 = 1 // VMIN
            raw.c_cc.17 = 0 // VTIME
        #elseif canImport(Glibc)
            raw.c_cc.6 = 1 // VMIN
            raw.c_cc.5 = 0 // VTIME
        #endif

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }

    /// Restores the original terminal mode saved by ``enableRawMode()``.
    public static func disableRawMode() {
        guard var original = originalTermios else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
        originalTermios = nil
    }

    // MARK: - Screen Control

    /// Writes a string directly to stdout, bypassing print buffering.
    public static func write(_ string: String) {
        string.withCString { ptr in
            _ = Foundation.write(STDOUT_FILENO, ptr, strlen(ptr))
        }
    }

    /// Writes raw bytes directly to stdout.
    public static func writeBytes(_ bytes: [UInt8]) {
        bytes.withUnsafeBufferPointer { buf in
            _ = Foundation.write(STDOUT_FILENO, buf.baseAddress, buf.count)
        }
    }

    /// Switches to the alternate screen buffer (saves current screen).
    public static func enterAlternateScreen() {
        write("\u{1B}[?1049h")
    }

    /// Switches back to the main screen buffer (restores saved screen).
    public static func leaveAlternateScreen() {
        write("\u{1B}[?1049l")
    }

    /// Hides the text cursor.
    public static func hideCursor() {
        write("\u{1B}[?25l")
    }

    /// Shows the text cursor.
    public static func showCursor() {
        write("\u{1B}[?25h")
    }

    /// Moves the cursor to a specific row and column (1-based).
    public static func moveCursor(row: Int, col: Int) {
        write("\u{1B}[\(row);\(col)H")
    }

    /// Clears the entire screen.
    public static func clearScreen() {
        write("\u{1B}[2J")
    }

    // MARK: - Signal Handling

    /// File descriptor pair for the resize self-pipe (async-signal-safe).
    private nonisolated(unsafe) static var resizePipeFDs: (read: Int32, write: Int32) = (-1, -1)

    /// The shutdown handler, if installed.
    private nonisolated(unsafe) static var shutdownHandler: (@Sendable () -> Void)?

    /// Registers a handler called on SIGTERM/SIGINT for graceful cleanup.
    public static func onShutdown(_ handler: @escaping @Sendable () -> Void) {
        shutdownHandler = handler
    }

    /// Returns an async stream that yields the new terminal size each time
    /// a SIGWINCH signal is received.
    ///
    /// Uses a self-pipe internally so that the signal handler only calls
    /// `write()` (which is async-signal-safe), and the actual size query
    /// happens on a detached task reading from the pipe.
    public static func resizeEvents() -> AsyncStream<Size> {
        AsyncStream { continuation in
            let fd = resizePipeFDs.read
            guard fd >= 0 else {
                continuation.finish()
                return
            }
            let readTask = Task.detached {
                while !Task.isCancelled {
                    var buf = [UInt8](repeating: 0, count: 1)
                    #if canImport(Darwin)
                        let n = Darwin.read(fd, &buf, 1)
                    #elseif canImport(Glibc)
                        let n = Glibc.read(fd, &buf, 1)
                    #else
                        let n = Foundation.read(fd, &buf, 1)
                    #endif
                    guard n > 0 else { break }
                    let size = Terminal.size()
                    continuation.yield(size)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                readTask.cancel()
            }
        }
    }

    /// Installs signal handlers for SIGWINCH (resize) and SIGTERM (shutdown).
    ///
    /// Call this once at startup. SIGWINCH writes a byte to a self-pipe
    /// (async-signal-safe); use ``resizeEvents()`` to consume resize events.
    /// SIGTERM forwards to the closure registered via ``onShutdown(_:)``.
    public static func installSignalHandlers() {
        // Create self-pipe for SIGWINCH
        var fds: [Int32] = [0, 0]
        _ = pipe(&fds)
        resizePipeFDs = (fds[0], fds[1])
        // Set write end to non-blocking so signal handler never blocks
        let flags = fcntl(fds[1], F_GETFL)
        _ = fcntl(fds[1], F_SETFL, flags | O_NONBLOCK)

        // SIGWINCH — write a byte to the pipe (async-signal-safe)
        signal(SIGWINCH) { _ in
            var byte: UInt8 = 1
            #if canImport(Darwin)
                _ = Darwin.write(Terminal.resizePipeFDs.write, &byte, 1)
            #elseif canImport(Glibc)
                _ = Glibc.write(Terminal.resizePipeFDs.write, &byte, 1)
            #endif
        }

        // SIGTERM — graceful shutdown
        signal(SIGTERM) { _ in
            Terminal.shutdownHandler?()
        }
    }
}
