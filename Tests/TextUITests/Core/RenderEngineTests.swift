import Testing
@testable import TextUI

@MainActor
@Suite("RenderEngine")
struct RenderEngineTests {
    // MARK: - Primitive Dispatch

    @Test("sizeThatFits dispatches to PrimitiveView")
    func sizePrimitive() {
        let view: any View = Text("Hi")
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == Size2D(width: 2, height: 1))
    }

    @Test("render dispatches to PrimitiveView")
    func renderPrimitive() {
        let view: any View = Text("AB")
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        TextUI.render(view, into: &buffer, region: region)
        #expect(buffer.text == "AB")
    }

    @Test("sizeThatFits dispatches to EmptyView")
    func sizeEmpty() {
        let view: any View = EmptyView()
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == .zero)
    }

    // MARK: - Composite Dispatch

    @Test("sizeThatFits recurses into composite body")
    func sizeComposite() {
        let view: any View = Wrapper()
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == Size2D(width: 5, height: 1))
    }

    @Test("render recurses into composite body")
    func renderComposite() {
        let view: any View = Wrapper()
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        TextUI.render(view, into: &buffer, region: region)
        #expect(buffer.text == "Hello")
    }

    // MARK: - ViewGroup Dispatch

    @Test("ViewGroup with zero children sizes to zero")
    func viewGroupEmpty() {
        let group: any View = ViewGroup([])
        let size = TextUI.sizeThatFits(group, proposal: .unspecified)
        #expect(size == .zero)
    }

    @Test("ViewGroup with one child sizes to that child")
    func viewGroupSingle() {
        let group: any View = ViewGroup([Text("AB")])
        let size = TextUI.sizeThatFits(group, proposal: .unspecified)
        #expect(size == Size2D(width: 2, height: 1))
    }

    // MARK: - Empty Region

    @Test("render into empty region does nothing")
    func renderEmptyRegion() {
        let view: any View = Text("Hello")
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 0, height: 0)
        TextUI.render(view, into: &buffer, region: region)
        #expect(buffer.text == "")
    }
}

// MARK: - Test Helpers

private struct Wrapper: View {
    var body: Text {
        Text("Hello")
    }
}
