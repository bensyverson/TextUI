import Testing
@testable import TextUI

@MainActor
@Suite("ColorCapability")
struct ColorCapabilityTests {
    // MARK: - Detection

    @Test("NO_COLOR disables color regardless of other vars")
    func noColor() {
        let cap = ColorCapability.detect(from: [
            "NO_COLOR": "",
            "COLORTERM": "truecolor",
        ])
        #expect(cap == .none)
    }

    @Test("COLORTERM=truecolor enables trueColor")
    func trueColorDetection() {
        let cap = ColorCapability.detect(from: ["COLORTERM": "truecolor"])
        #expect(cap == .trueColor)
    }

    @Test("COLORTERM=24bit enables trueColor")
    func twentyFourBitDetection() {
        let cap = ColorCapability.detect(from: ["COLORTERM": "24bit"])
        #expect(cap == .trueColor)
    }

    @Test("TERM with 256color enables palette256")
    func palette256Detection() {
        let cap = ColorCapability.detect(from: ["TERM": "xterm-256color"])
        #expect(cap == .palette256)
    }

    @Test("TERM=dumb disables color")
    func dumbTerminal() {
        let cap = ColorCapability.detect(from: ["TERM": "dumb"])
        #expect(cap == .none)
    }

    @Test("default with no environment is basic16")
    func defaultBasic() {
        let cap = ColorCapability.detect(from: [:])
        #expect(cap == .basic16)
    }

    // MARK: - Color Downgrading

    @Test("RGB downgraded to palette256 produces palette color")
    func rgbToPalette() {
        let color = Style.Color.rgb(255, 0, 0)
        let result = color.downgraded(to: .palette256)
        if case .palette = result {} else {
            Issue.record("Expected .palette, got \(String(describing: result))")
        }
    }

    @Test("basic16 colors are unchanged when downgrading to basic16")
    func basic16Passthrough() {
        let color = Style.Color.red
        let result = color.downgraded(to: .basic16)
        #expect(result == .red)
    }

    @Test("color downgraded to none returns nil")
    func noneStripsColor() {
        let color = Style.Color.red
        let result = color.downgraded(to: .none)
        #expect(result == nil)
    }

    @Test("RGB to basic16 finds nearest match")
    func rgbToBasic16() {
        // Pure red should map to red
        let color = Style.Color.rgb(200, 10, 10)
        let result = color.downgraded(to: .basic16)
        #expect(result == .red)
    }

    // MARK: - Comparable

    @Test("capabilities are ordered correctly")
    func ordering() {
        #expect(ColorCapability.none < .basic16)
        #expect(ColorCapability.basic16 < .palette256)
        #expect(ColorCapability.palette256 < .trueColor)
    }
}
