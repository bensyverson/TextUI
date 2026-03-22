public extension Terminal {
    /// Enables SGR extended mouse tracking.
    ///
    /// Sends mode 1002 (button-event tracking: press, release, and drag) and
    /// mode 1006 (SGR extended format with no coordinate limits).
    ///
    /// Call ``disableMouseTracking()`` before leaving raw mode to restore
    /// normal terminal behavior.
    static func enableMouseTracking() {
        write("\u{1B}[?1002h") // Button-event tracking
        write("\u{1B}[?1006h") // SGR extended format
    }

    /// Disables mouse tracking, restoring default terminal behavior.
    ///
    /// Disables SGR extended format first, then button-event tracking
    /// (reverse of the enable order).
    static func disableMouseTracking() {
        write("\u{1B}[?1006l") // Disable SGR extended format
        write("\u{1B}[?1002l") // Disable button-event tracking
    }
}
