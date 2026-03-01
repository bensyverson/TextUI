#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif
import Foundation

/// Reads raw bytes from stdin on a detached thread and produces
/// an `AsyncStream` of ``KeyEvent``s.
///
/// The reader runs on a detached OS thread (not a cooperative task)
/// because `read(STDIN_FILENO)` blocks and cannot be cancelled by
/// structured concurrency. A 50ms `poll()` timeout disambiguates
/// standalone ESC from the start of an escape sequence.
///
/// ```swift
/// let reader = KeyReader()
/// reader.start()
/// for await key in reader.events {
///     // handle key
/// }
/// ```
public final class KeyReader: Sendable {
    private let stream: AsyncStream<KeyEvent>
    private let continuation: AsyncStream<KeyEvent>.Continuation

    /// The async stream of parsed key events.
    public var events: AsyncStream<KeyEvent> {
        stream
    }

    /// Creates a new key reader.
    public init() {
        let (stream, continuation) = AsyncStream<KeyEvent>.makeStream(
            bufferingPolicy: .bufferingNewest(64),
        )
        self.stream = stream
        self.continuation = continuation
    }

    /// Starts reading from stdin.
    ///
    /// Call this once; the reader runs until ``stop()`` is called or stdin closes.
    public func start() {
        let continuation = continuation
        Thread.detachNewThread {
            var buf = [UInt8](repeating: 0, count: 256)
            while true {
                let bytesRead = read(STDIN_FILENO, &buf, buf.count)
                guard bytesRead > 0 else {
                    continuation.finish()
                    return
                }

                var bytes = Array(buf[0 ..< bytesRead])
                var offset = 0

                while offset < bytes.count {
                    let slice = Array(bytes[offset...])

                    // Handle standalone escape: if ESC is the only remaining byte,
                    // wait briefly for the rest of an escape sequence
                    if slice.count == 1, slice[0] == 0x1B {
                        var moreBuf = [UInt8](repeating: 0, count: 32)
                        var pfd = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
                        let ready = poll(&pfd, 1, 50) // 50ms timeout
                        if ready > 0 {
                            let moreRead = read(STDIN_FILENO, &moreBuf, moreBuf.count)
                            if moreRead > 0 {
                                bytes.append(contentsOf: moreBuf[0 ..< moreRead])
                                continue // Re-parse with the extended buffer
                            }
                        }
                    }

                    if let (event, consumed) = KeyEvent.parse(slice) {
                        let result = continuation.yield(event)
                        if case .terminated = result { return }
                        offset += consumed
                    } else {
                        offset += 1
                    }
                }
            }
        }
    }

    /// Stops the key reader and finishes the event stream.
    public func stop() {
        continuation.finish()
    }
}
