import Testing
@testable import TextUI

/// Mutable value for use in test closures.
private final class Box<T: Sendable> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

@MainActor
@Suite("Toggle")
struct ToggleTests {
    @Test("Sizing is 4 + label display width × 1")
    func sizing() {
        let toggle = Toggle("Dark mode", isOn: false) { _ in }
        let size = sizeThatFits(toggle, proposal: SizeProposal(width: 40, height: 10))
        // "[x] " = 4 chars + "Dark mode" = 9
        #expect(size == Size2D(width: 13, height: 1))
    }

    @Test("On state renders [x]")
    func onRendering() {
        let toggle = Toggle("Test", isOn: true) { _ in }
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        render(toggle, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "[")
        #expect(buffer[0, 1].char == "x")
        #expect(buffer[0, 2].char == "]")
        #expect(buffer[0, 3].char == " ")
        #expect(buffer[0, 4].char == "T")
    }

    @Test("Off state renders [ ]")
    func offRendering() {
        let toggle = Toggle("Test", isOn: false) { _ in }
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        render(toggle, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "[")
        #expect(buffer[0, 1].char == " ")
        #expect(buffer[0, 2].char == "]")
    }

    @Test("Space toggles via onChange when focused")
    func spaceToggles() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(false)
        let toggle = Toggle("Test", isOn: false) { newValue in
            received.value = newValue
        }

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(toggle, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(toggle, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.character(" "))
        #expect(result == .handled)
        #expect(received.value == true) // toggled from false → true
    }

    @Test("Enter toggles via onChange when focused")
    func enterToggles() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(false)
        let toggle = Toggle("Test", isOn: false) { newValue in
            received.value = newValue
        }

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(toggle, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(toggle, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(received.value == true)
    }
}
