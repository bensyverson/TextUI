// Terminal display width calculations for Unicode characters.
//
// Terminal emulators use a fixed-width grid where each cell holds one column.
// Most characters occupy 1 column, but CJK ideographs and emoji occupy 2,
// while combining marks and zero-width characters occupy 0.

public extension Character {
    /// The number of terminal columns this character occupies (0, 1, or 2).
    var displayWidth: Int {
        let scalars = unicodeScalars

        // 1. Emoji with presentation — always 2 columns
        //    Use isEmojiPresentation (NOT isEmoji — isEmoji is true for digits)
        if scalars.contains(where: \.properties.isEmojiPresentation) { return 2 }

        // 2. Variation Selector 16 (U+FE0F) promotes text-style emoji to wide
        if scalars.contains(where: { $0.value == 0xFE0F }) { return 2 }

        // 3. ZWJ sequences — always 2 columns
        if scalars.contains(where: { $0.value == 0x200D }) { return 2 }

        // 4. Regional indicator pairs (flag emoji) — 2 columns
        if scalars.contains(where: { (0x1F1E6 ... 0x1F1FF).contains($0.value) }) { return 2 }

        // 5. Skin tone modifiers — 2 columns
        if scalars.contains(where: { (0x1F3FB ... 0x1F3FF).contains($0.value) }) { return 2 }

        // 6. Keycap combining sequences (1️⃣, 2️⃣, etc.)
        if scalars.contains(where: { $0.value == 0x20E3 }) { return 2 }

        // 7. CJK ranges — 2 columns
        if scalars.contains(where: { isCJK($0) }) { return 2 }

        // 8. Zero-width characters (combining marks, format chars)
        if scalars.allSatisfy({ isZeroWidth($0) }) { return 0 }

        // 9. Everything else — 1 column
        return 1
    }
}

public extension String {
    /// Total terminal display width of this string.
    var displayWidth: Int {
        reduce(0) { $0 + $1.displayWidth }
    }
}

// MARK: - Private Helpers

/// Whether a scalar falls within CJK ranges that are double-width.
private func isCJK(_ scalar: Unicode.Scalar) -> Bool {
    let v = scalar.value
    return
        // Hangul Jamo
        (0x1100 ... 0x115F).contains(v) ||
        // Hangul Jamo Extended-A
        (0xA960 ... 0xA97C).contains(v) ||
        // Hangul Syllables
        (0xAC00 ... 0xD7AF).contains(v) ||
        // Hangul Jamo Extended-B
        (0xD7B0 ... 0xD7FF).contains(v) ||
        // CJK Radicals Supplement, Kangxi Radicals
        (0x2E80 ... 0x2FDF).contains(v) ||
        // Ideographic Description Characters, CJK Symbols and Punctuation
        (0x2FF0 ... 0x303E).contains(v) ||
        // Hiragana
        (0x3040 ... 0x309F).contains(v) ||
        // Katakana
        (0x30A0 ... 0x30FF).contains(v) ||
        // Bopomofo
        (0x3100 ... 0x312F).contains(v) ||
        // CJK Compatibility
        (0x3130 ... 0x318F).contains(v) ||
        // Katakana Phonetic Extensions
        (0x31F0 ... 0x31FF).contains(v) ||
        // Enclosed CJK Letters and Months
        (0x3200 ... 0x32FF).contains(v) ||
        // CJK Compatibility
        (0x3300 ... 0x33FF).contains(v) ||
        // CJK Unified Ideographs Extension A
        (0x3400 ... 0x4DBF).contains(v) ||
        // CJK Unified Ideographs
        (0x4E00 ... 0x9FFF).contains(v) ||
        // Yi Syllables, Yi Radicals
        (0xA000 ... 0xA4CF).contains(v) ||
        // CJK Compatibility Ideographs
        (0xF900 ... 0xFAFF).contains(v) ||
        // Fullwidth Forms (excluding halfwidth)
        (0xFF01 ... 0xFF60).contains(v) ||
        // CJK Unified Ideographs Extension B–F, Supplement
        (0x20000 ... 0x2FA1F).contains(v)
}

/// Whether a scalar is zero-width (combining marks, format characters, etc.).
private func isZeroWidth(_ scalar: Unicode.Scalar) -> Bool {
    // Default ignorable code points (soft hyphens, zero-width spaces, etc.)
    if scalar.properties.isDefaultIgnorableCodePoint { return true }

    // Combining marks
    switch scalar.properties.generalCategory {
    case .nonspacingMark, .spacingMark, .enclosingMark:
        return true
    default:
        break
    }

    let v = scalar.value
    // Variation selectors (VS1–VS16 and VS17–VS256)
    if (0xFE00 ... 0xFE0F).contains(v) || (0xE0100 ... 0xE01EF).contains(v) {
        return true
    }

    return false
}
