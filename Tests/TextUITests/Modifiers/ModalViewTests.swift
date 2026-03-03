import Testing
@testable import TextUI

/// Thread-safe mutable flag for use in `@Sendable` test closures.
private final class Flag: @unchecked Sendable {
    var value: Bool = false
}

@Suite("ModalView")
struct ModalViewTests {
    @Test("Not presented passes through to background unchanged")
    func notPresentedPassthrough() {
        let view = Text("Hello")
            .modal(isPresented: false) { Text("Modal") }

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        render(view, into: &buffer, region: region)

        #expect(buffer[0, 0].char == "H")
        #expect(buffer[0, 4].char == "o")
        #expect(!buffer[0, 0].style.dim)
    }

    @Test("Presented sizing matches background")
    func presentedSizingMatchesBackground() {
        let bg = Text("Hello World")
        let bgSize = sizeThatFits(bg, proposal: SizeProposal(width: 40, height: 10))

        let modal = bg.modal(isPresented: true) { Text("M") }
        let modalSize = sizeThatFits(modal, proposal: SizeProposal(width: 40, height: 10))

        #expect(bgSize == modalSize)
    }

    @Test("Background button does not register in focus ring when modal presented")
    func focusSuppression() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = Button("BG") {}.modal(isPresented: true) {
            Text("Info")
        }
        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        // No focusable controls (Text is not focusable, background Button is suppressed)
        #expect(store.ring.count == 0)
    }

    @Test("Modal body button registers in focus ring")
    func modalFocus() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = Text("BG").modal(isPresented: true) {
            Button("OK") {}
        }
        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count == 1)
    }

    @Test("Background cells have dim styling when modal presented")
    func scrimDim() {
        let view = Text("Hello")
            .modal(isPresented: true) { Text("M") }

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region)

        // Row 0 has background text — should be dimmed
        #expect(buffer[0, 0].style.dim)
    }

    @Test("Modal body cells are not dimmed")
    func modalBodyNotDimmed() {
        let view = Text("Hello")
            .modal(isPresented: true) { Text("M") }

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region)

        // Find the "M" character — it should not be dim
        // With 10 wide and 3 tall, modal "M" (1x1) should be centered at roughly (1, 4)
        let modalRow = 1
        let modalCol = 4
        #expect(buffer[modalRow, modalCol].char == "M")
        #expect(!buffer[modalRow, modalCol].style.dim)
    }

    @Test("Modal body renders centered in the region")
    func centered() {
        let view = Text("Background text here")
            .modal(isPresented: true) { Text("Hi") }

        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)
        render(view, into: &buffer, region: region)

        // "Hi" is 2 wide, 1 tall. Centered in 20x5 → col 9, row 2
        #expect(buffer[2, 9].char == "H")
        #expect(buffer[2, 10].char == "i")
    }

    @Test("Escape calls onDismiss when provided")
    func escapeDismissal() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let dismissed = Flag()
        let view = Text("BG").modal(
            isPresented: true,
            onDismiss: { dismissed.value = true },
        ) {
            Button("OK") {}
        }

        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.escape)
        #expect(result == .handled)
        #expect(dismissed.value)
    }

    @Test("Escape is not consumed when onDismiss is nil")
    func noEscapeInterception() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = Text("BG").modal(isPresented: true) {
            Button("OK") {}
        }

        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.escape)
        #expect(result == .ignored)
    }
}
