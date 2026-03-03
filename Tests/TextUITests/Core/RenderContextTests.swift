import Testing
@testable import TextUI

@MainActor
@Suite("RenderContext")
struct RenderContextTests {
    @MainActor
    final class Counter: Sendable {
        let value: Int
        init(value: Int = 0) {
            self.value = value
        }
    }

    @MainActor
    final class Label: Sendable {
        let text: String
        init(text: String) {
            self.text = text
        }
    }

    @Test("empty context returns nil for any type")
    func emptyLookup() {
        let ctx = RenderContext()
        #expect(ctx.environmentObject(ofType: Counter.self) == nil)
    }

    @Test("inserting and retrieving an object by type")
    func insertAndRetrieve() async {
        await MainActor.run {
            let counter = Counter(value: 42)
            let ctx = RenderContext().inserting(counter)
            let retrieved = ctx.environmentObject(ofType: Counter.self)
            #expect(retrieved === counter)
            #expect(retrieved?.value == 42)
        }
    }

    @Test("inserting preserves value semantics — original unchanged")
    func valueSemantics() async {
        await MainActor.run {
            let original = RenderContext()
            let counter = Counter(value: 1)
            let modified = original.inserting(counter)
            #expect(original.environmentObject(ofType: Counter.self) == nil)
            #expect(modified.environmentObject(ofType: Counter.self) != nil)
        }
    }

    @Test("multiple types coexist in context")
    func multipleTypes() async {
        await MainActor.run {
            let counter = Counter(value: 10)
            let label = Label(text: "hello")
            let ctx = RenderContext()
                .inserting(counter)
                .inserting(label)
            #expect(ctx.environmentObject(ofType: Counter.self)?.value == 10)
            #expect(ctx.environmentObject(ofType: Label.self)?.text == "hello")
        }
    }

    @Test("inserting same type replaces previous object")
    func replacesSameType() async {
        await MainActor.run {
            let first = Counter(value: 1)
            let second = Counter(value: 2)
            let ctx = RenderContext()
                .inserting(first)
                .inserting(second)
            #expect(ctx.environmentObject(ofType: Counter.self)?.value == 2)
        }
    }
}
