import Testing
@testable import TextUI

@Suite("FocusState")
struct FocusStateTests {
    @Test("FocusState reads focused binding key from store")
    func readsFocusedKey() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("name"),
            autoKey: nil,
        )
        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("email"),
            autoKey: nil,
        )
        store.setFocusByBindingKey(AnyHashable("email"))

        var ctx = RenderContext()
        ctx.focusStore = store

        // Simulate view body evaluation with the store in context
        let value: String? = RenderEnvironment.$current.withValue(ctx) {
            var state = FocusState<String?>()
            return state.wrappedValue
        }
        #expect(value == "email")
    }

    @Test("FocusState returns nil when nothing focused")
    func nilWhenNothingFocused() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let value: String? = RenderEnvironment.$current.withValue(ctx) {
            var state = FocusState<String?>()
            return state.wrappedValue
        }
        #expect(value == nil)
    }

    @Test("FocusState set moves focus via store")
    func setMovesFocus() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("name"),
            autoKey: nil,
        )
        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("email"),
            autoKey: nil,
        )

        var ctx = RenderContext()
        ctx.focusStore = store

        RenderEnvironment.$current.withValue(ctx) {
            var state = FocusState<String?>()
            state.wrappedValue = "email"
        }

        #expect(store.focusedIndex == 1)
        #expect(store.focusedBindingKey == AnyHashable("email"))
    }

    @Test("FocusState set to nil removes focus")
    func setNilRemovesFocus() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("name"),
            autoKey: nil,
        )
        store.setFocusByBindingKey(AnyHashable("name"))
        #expect(store.focusedIndex == 0)

        var ctx = RenderContext()
        ctx.focusStore = store

        RenderEnvironment.$current.withValue(ctx) {
            var state = FocusState<String?>()
            state.wrappedValue = nil
        }

        #expect(store.focusedIndex == nil)
    }
}
