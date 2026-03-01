/// Color downgrading for terminal capability matching.
///
/// When the terminal supports fewer colors than the style specifies,
/// colors are downgraded: RGB → nearest palette-256 → nearest basic-16.
extension Style.Color {
    /// Returns a color downgraded to match the given capability level.
    ///
    /// - `.trueColor`: no change
    /// - `.palette256`: RGB → nearest 256-color palette entry
    /// - `.basic16`: RGB/palette → nearest basic-16 color
    /// - `.none`: always returns `nil` (caller should strip color)
    func downgraded(to capability: ColorCapability) -> Style.Color? {
        switch capability {
        case .trueColor:
            self
        case .palette256:
            downgradeToPalette256()
        case .basic16:
            downgradeToBasic16()
        case .none:
            nil
        }
    }

    // MARK: - RGB → Palette 256

    private func downgradeToPalette256() -> Style.Color {
        switch self {
        case let .rgb(r, g, b):
            .palette(Self.nearestPalette256(r: r, g: g, b: b))
        default:
            self // basic-16 and palette are already ≤ 256
        }
    }

    /// Finds the nearest 256-color palette index for an RGB color.
    ///
    /// The 256-color palette is structured:
    /// - 0–15: basic 16 colors (handled as basic16 names)
    /// - 16–231: 6×6×6 color cube
    /// - 232–255: 24-step grayscale
    private static func nearestPalette256(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {
        // Check grayscale first
        if r == g, g == b {
            if r < 8 { return 16 } // black end of cube
            if r > 248 { return 231 } // white end of cube
            return UInt8(232 + (Int(r) - 8) * 24 / 240)
        }

        // Map to 6×6×6 color cube (indices 16–231)
        let ri = colorCubeIndex(r)
        let gi = colorCubeIndex(g)
        let bi = colorCubeIndex(b)
        return UInt8(16 + 36 * ri + 6 * gi + bi)
    }

    /// Maps a 0–255 value to a 0–5 color cube index.
    private static func colorCubeIndex(_ value: UInt8) -> Int {
        // The cube steps are: 0, 95, 135, 175, 215, 255
        // Find the nearest one
        let steps: [Int] = [0, 95, 135, 175, 215, 255]
        var bestIndex = 0
        var bestDist = abs(Int(value) - steps[0])
        for (i, step) in steps.enumerated().dropFirst() {
            let dist = abs(Int(value) - step)
            if dist < bestDist {
                bestDist = dist
                bestIndex = i
            }
        }
        return bestIndex
    }

    // MARK: - Any → Basic 16

    private func downgradeToBasic16() -> Style.Color {
        switch self {
        case .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white,
             .brightBlack, .brightRed, .brightGreen, .brightYellow,
             .brightBlue, .brightMagenta, .brightCyan, .brightWhite:
            self
        case let .palette(n):
            Self.paletteToBasic16(n)
        case let .rgb(r, g, b):
            Self.rgbToBasic16(r: r, g: g, b: b)
        }
    }

    /// Maps a 256-color palette index to the nearest basic-16 color.
    private static func paletteToBasic16(_ index: UInt8) -> Style.Color {
        // Palette 0–15 map directly to basic-16
        if index < 16 {
            return basic16Colors[Int(index)]
        }
        // For 16–255, convert palette to RGB then find nearest basic-16
        let (r, g, b) = paletteToRGB(index)
        return rgbToBasic16(r: r, g: g, b: b)
    }

    /// Converts a 256-color palette index to approximate RGB values.
    private static func paletteToRGB(_ index: UInt8) -> (UInt8, UInt8, UInt8) {
        if index < 16 {
            return basic16RGB[Int(index)]
        }
        if index < 232 {
            // 6×6×6 color cube
            let adjusted = Int(index) - 16
            let ri = adjusted / 36
            let gi = (adjusted % 36) / 6
            let bi = adjusted % 6
            let steps: [UInt8] = [0, 95, 135, 175, 215, 255]
            return (steps[ri], steps[gi], steps[bi])
        }
        // Grayscale: 232–255 → 8, 18, ..., 238
        let gray = UInt8(8 + (Int(index) - 232) * 10)
        return (gray, gray, gray)
    }

    /// Finds the nearest basic-16 color for an RGB value.
    private static func rgbToBasic16(r: UInt8, g: UInt8, b: UInt8) -> Style.Color {
        var bestColor = Style.Color.black
        var bestDist = Int.max
        for (i, (cr, cg, cb)) in basic16RGB.enumerated() {
            let dr = Int(r) - Int(cr)
            let dg = Int(g) - Int(cg)
            let db = Int(b) - Int(cb)
            let dist = dr * dr + dg * dg + db * db
            if dist < bestDist {
                bestDist = dist
                bestColor = basic16Colors[i]
            }
        }
        return bestColor
    }

    /// The basic-16 colors in order.
    private static let basic16Colors: [Style.Color] = [
        .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white,
        .brightBlack, .brightRed, .brightGreen, .brightYellow,
        .brightBlue, .brightMagenta, .brightCyan, .brightWhite,
    ]

    /// Approximate RGB values for the basic-16 ANSI colors.
    private static let basic16RGB: [(UInt8, UInt8, UInt8)] = [
        (0, 0, 0), // black
        (170, 0, 0), // red
        (0, 170, 0), // green
        (170, 170, 0), // yellow
        (0, 0, 170), // blue
        (170, 0, 170), // magenta
        (0, 170, 170), // cyan
        (170, 170, 170), // white
        (85, 85, 85), // brightBlack
        (255, 85, 85), // brightRed
        (85, 255, 85), // brightGreen
        (255, 255, 85), // brightYellow
        (85, 85, 255), // brightBlue
        (255, 85, 255), // brightMagenta
        (85, 255, 255), // brightCyan
        (255, 255, 255), // brightWhite
    ]
}

/// Style-level color downgrading.
extension Style {
    /// Returns a copy of this style with colors downgraded to the given capability.
    func downgraded(to capability: ColorCapability) -> Style {
        guard capability < .trueColor else { return self }
        var copy = self
        if let fg {
            copy.fg = fg.downgraded(to: capability)
        }
        if let bg {
            copy.bg = bg.downgraded(to: capability)
        }
        return copy
    }
}
