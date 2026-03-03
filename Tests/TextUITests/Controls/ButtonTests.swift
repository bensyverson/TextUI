import Testing
@testable import TextUI

/// Mutable flag for use in test closures.
private final class Flag {
    var value: Bool = false
}

@MainActor
@Suite("Button")
struct ButtonTests {
    @Test("Sizing hugs label content")
    func sizingHugsLabel() {
        let button = Button("OK") {}
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10))
        #expect(size == Size2D(width: 2, height: 1)) // "OK" = 2 wide
    }

    @Test("Sizing hugs multi-character label")
    func sizingHugsLongerLabel() {
        let button = Button("Submit") {}
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10))
        #expect(size == Size2D(width: 6, height: 1))
    }

    @Test("Unfocused button renders label normally")
    func unfocusedRendering() {
        let button = Button("OK") {}
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        render(button, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "O")
        #expect(buffer[0, 1].char == "K")
        #expect(!buffer[0, 0].style.inverse)
    }

    @Test("Focused button renders with inverse styling")
    func focusedRendering() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let button = Button("OK") {}
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(button, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        // Re-render with focus applied
        store.beginFrame()
        buffer = Buffer(width: 10, height: 1)
        render(button, into: &buffer, region: region, context: ctx)

        #expect(buffer[0, 0].char == "O")
        #expect(buffer[0, 0].style.inverse)
        #expect(buffer[0, 1].style.inverse)
    }

    @Test("Enter fires action on focused button")
    func enterFiresAction() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let fired = Flag()
        let button = Button("OK") { fired.value = true }
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(button, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(button, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(fired.value)
    }

    @Test("Space fires action on focused button")
    func spaceFiresAction() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let fired = Flag()
        let button = Button("OK") { fired.value = true }
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(button, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(button, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.character(" "))
        #expect(result == .handled)
        #expect(fired.value)
    }
}
