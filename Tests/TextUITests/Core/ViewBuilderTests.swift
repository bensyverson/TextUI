import Testing
@testable import TextUI

@Suite("ViewBuilder")
struct ViewBuilderTests {
    @Test("buildBlock with zero components produces empty ViewGroup")
    func buildBlockEmpty() {
        let group = ViewBuilder.buildBlock()
        #expect(group.children.isEmpty)
    }

    @Test("buildBlock with one component wraps in ViewGroup")
    func buildBlockSingle() {
        let group = ViewBuilder.buildBlock(EmptyView())
        #expect(group.children.count == 1)
        #expect(group.children[0] is EmptyView)
    }

    @Test("buildBlock with three components preserves order")
    func buildBlockMultiple() {
        let a = StubView(tag: "a")
        let b = StubView(tag: "b")
        let c = StubView(tag: "c")
        let group = ViewBuilder.buildBlock(a, b, c)
        #expect(group.children.count == 3)
        #expect((group.children[0] as? StubView)?.tag == "a")
        #expect((group.children[1] as? StubView)?.tag == "b")
        #expect((group.children[2] as? StubView)?.tag == "c")
    }

    @Test("buildOptional with nil returns EmptyView")
    func buildOptionalNil() {
        let view = ViewBuilder.buildOptional(nil)
        #expect(view is EmptyView)
    }

    @Test("buildOptional with value passes through")
    func buildOptionalValue() {
        let stub = StubView(tag: "x")
        let view = ViewBuilder.buildOptional(stub)
        #expect((view as? StubView)?.tag == "x")
    }

    @Test("buildArray wraps in ViewGroup")
    func buildArray() {
        let views: [any View] = [StubView(tag: "1"), StubView(tag: "2")]
        let group = ViewBuilder.buildArray(views)
        #expect(group.children.count == 2)
    }

    @Test("@ViewBuilder closure with if/else")
    func viewBuilderIfElse() {
        let condition = true
        @ViewBuilder func build() -> ViewGroup {
            if condition {
                StubView(tag: "yes")
            } else {
                StubView(tag: "no")
            }
        }
        let group = build()
        #expect(group.children.count == 1)
    }

    @Test("@ViewBuilder closure with for loop")
    func viewBuilderForLoop() {
        @ViewBuilder func build() -> ViewGroup {
            for i in 0 ..< 3 {
                StubView(tag: "\(i)")
            }
        }
        let group = build()
        // for loop produces a ViewGroup child containing 3 items
        #expect(group.children.count == 1)
        let inner = group.children[0] as? ViewGroup
        #expect(inner?.children.count == 3)
    }

    // MARK: - ViewGroup

    @Test("ViewGroup with no children sizes to zero")
    func viewGroupEmptySize() {
        let group = ViewGroup([])
        #expect(group.sizeThatFits(.unspecified) == .zero)
    }

    @Test("ViewGroup with one child sizes to that child")
    func viewGroupSingleChildSize() {
        let text = Text("Hi")
        let group = ViewGroup([text])
        let size = group.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 2, height: 1))
    }
}

// MARK: - Test Helpers

private struct StubView: PrimitiveView, Sendable {
    let tag: String

    func sizeThatFits(_: SizeProposal) -> Size2D {
        .zero
    }

    func render(into _: inout Buffer, region _: Region) {}
}
