import Testing
@testable import TextUI

@Suite("View Protocols")
struct ViewProtocolTests {
    // MARK: - PrimitiveView Dispatch

    @Test("PrimitiveView sizeThatFits dispatches correctly")
    func primitiveSizing() {
        let stub = StubPrimitive(fixedSize: Size2D(width: 5, height: 3))
        let size = stub.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 5, height: 3))
    }

    @Test("PrimitiveView render dispatches correctly")
    func primitiveRender() {
        let stub = StubPrimitive(fixedSize: Size2D(width: 3, height: 1))
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        stub.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "X")
    }

    // MARK: - Composite View

    @Test("Composite view body returns expected type")
    func compositeBody() {
        let composite = StubComposite()
        // body should be the StubPrimitive
        let size = TextUI.sizeThatFits(composite, proposal: .unspecified)
        #expect(size == Size2D(width: 5, height: 1))
    }

    @Test("Composite view renders through body")
    func compositeRender() {
        let composite = StubComposite()
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        TextUI.render(composite, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "X")
    }
}

// MARK: - Test Helpers

private struct StubPrimitive: PrimitiveView {
    let fixedSize: Size2D

    func sizeThatFits(_: SizeProposal) -> Size2D {
        fixedSize
    }

    func render(into buffer: inout Buffer, region: Region) {
        guard !region.isEmpty else { return }
        buffer.write("X", row: region.row, col: region.col)
    }
}

private struct StubComposite: View {
    var body: StubPrimitive {
        StubPrimitive(fixedSize: Size2D(width: 5, height: 1))
    }
}
