import Testing
@testable import TextUI

@Suite("EnvironmentObject")
struct EnvironmentObjectTests {
    @MainActor
    final class TestModel: Sendable {
        let label: String
        init(label: String) {
            self.label = label
        }
    }

    @MainActor
    final class OtherModel: Sendable {
        let value: Int
        init(value: Int) {
            self.value = value
        }
    }

    @Test("environmentObject modifier injects into context")
    @MainActor
    func injection() {
        let model = TestModel(label: "hello")
        let view = Text("test").environmentObject(model)
        // Should size without crashing — the object is available in context
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == Size2D(width: 4, height: 1))
    }

    @Test("environmentObject is readable during body evaluation")
    @MainActor
    func readDuringBody() {
        let model = TestModel(label: "world")
        let view = ReaderView().environmentObject(model)
        // ReaderView.body reads from @EnvironmentObject and creates Text
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == Size2D(width: 5, height: 1)) // "world" = 5
    }

    @Test("environmentObject renders correctly")
    @MainActor
    func renderWithEnvObject() {
        let model = TestModel(label: "Hi")
        let view = ReaderView().environmentObject(model)
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        TextUI.render(view, into: &buffer, region: region)
        #expect(buffer.text == "Hi")
    }

    @Test("multiple environment objects coexist")
    @MainActor
    func multipleObjects() {
        let model = TestModel(label: "test")
        let other = OtherModel(value: 42)
        let view = ReaderView()
            .environmentObject(model)
            .environmentObject(other)
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == Size2D(width: 4, height: 1)) // "test" = 4
    }

    @Test("inner environmentObject overrides outer for same type")
    @MainActor
    func innerOverridesOuter() {
        let outer = TestModel(label: "outer")
        let inner = TestModel(label: "inner")
        let view = ReaderView()
            .environmentObject(inner)
            .environmentObject(outer) // outer wraps inner, but inner is closer to ReaderView
        // Wait — the wrapping order means outer is evaluated first, then inner.
        // .environmentObject(outer) wraps .environmentObject(inner) wraps ReaderView
        // So the context has outer, then inner replaces it. Inner wins.
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        #expect(size == Size2D(width: 5, height: 1)) // "inner" = 5
    }

    @Test("EnvironmentObjectView passes context through for sizing and rendering")
    @MainActor
    func passesContextThrough() {
        let model = TestModel(label: "AB")
        let view = ReaderView()
            .padding(1)
            .environmentObject(model)
        let size = TextUI.sizeThatFits(view, proposal: .unspecified)
        // "AB" width 2 + padding 2 = 4, height 1 + padding 2 = 3
        #expect(size == Size2D(width: 4, height: 3))
    }
}

// MARK: - Test Helpers

/// A view that reads a `TestModel` from the environment and displays its label.
private struct ReaderView: View {
    var body: some View {
        let model = RenderEnvironment.current.environmentObject(
            ofType: EnvironmentObjectTests.TestModel.self,
        )!
        return Text(model.label)
    }
}
