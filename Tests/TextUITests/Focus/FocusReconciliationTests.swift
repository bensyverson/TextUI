import Testing
@testable import TextUI

@MainActor
@Suite("FocusStore Reconciliation")
struct FocusReconciliationTests {
    private let region = Region(row: 0, col: 0, width: 10, height: 1)

    // MARK: - First Frame

    @Test("reconcileFocus focuses first control on first frame")
    func firstFrameFocus() {
        let store = FocusStore()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "b")

        let changed = store.reconcileFocus()
        #expect(changed)
        #expect(store.focusedIndex == 0)
    }

    @Test("reconcileFocus uses defaultFocusTarget on first frame")
    func firstFrameDefaultTarget() {
        let store = FocusStore()
        store.defaultFocusTarget = AnyHashable("email")

        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: AnyHashable("name"), autoKey: nil)
        store.register(interaction: .edit, region: region, sectionID: nil, bindingKey: AnyHashable("email"), autoKey: nil)

        let changed = store.reconcileFocus()
        #expect(changed)
        #expect(store.focusedIndex == 1)
    }

    // MARK: - Stable Ring

    @Test("reconcileFocus returns false when focused control is unchanged")
    func stableRing() {
        let store = FocusStore()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "b")
        store.reconcileFocus() // first frame — focuses "a"

        // Simulate second frame: same controls
        store.beginFrame()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "b")

        let changed = store.reconcileFocus()
        #expect(!changed)
        #expect(store.focusedIndex == 0)
    }

    // MARK: - Ring Shrinks

    @Test("reconcileFocus keeps focus when focused control survives ring shrink")
    func ringShrinkFocusedSurvives() {
        let store = FocusStore()
        store.register(interaction: .edit, region: region, sectionID: nil, bindingKey: nil, autoKey: "field")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "send")
        store.reconcileFocus() // focuses "field" at index 0

        // Simulate next frame: "send" is disabled, only "field" remains
        store.beginFrame()
        store.register(interaction: .edit, region: region, sectionID: nil, bindingKey: nil, autoKey: "field")

        let changed = store.reconcileFocus()
        #expect(!changed) // still index 0, still "field"
        #expect(store.focusedIndex == 0)
    }

    @Test("reconcileFocus resets to 0 when focused control is removed")
    func focusedControlRemoved() {
        let store = FocusStore()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "b")
        store.reconcileFocus()
        store.focusNext() // focus "b" at index 1

        // Next frame: "b" is gone
        store.beginFrame()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")

        let changed = store.reconcileFocus()
        #expect(changed)
        #expect(store.focusedIndex == 0) // reset to first
    }

    // MARK: - View Transition

    @Test("reconcileFocus resets to 0 when ring composition changes entirely")
    func viewTransition() {
        let store = FocusStore()
        // Picker screen: Picker + Start
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "picker")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "start")
        store.reconcileFocus()
        store.focusNext() // focus "start" at index 1

        // Transition to chat screen: TextField + Send
        store.beginFrame()
        store.register(interaction: .edit, region: region, sectionID: nil, bindingKey: nil, autoKey: "textfield")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "send")

        let changed = store.reconcileFocus()
        #expect(changed)
        #expect(store.focusedIndex == 0) // "textfield", not "send"
    }

    // MARK: - Reorder

    @Test("reconcileFocus follows focused control when ring is reordered")
    func reorderedRing() {
        let store = FocusStore()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "b")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "c")
        store.reconcileFocus()
        store.focusNext() // focus "b" at index 1

        // Next frame: controls reordered (c, a, b)
        store.beginFrame()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "c")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "b")

        let changed = store.reconcileFocus()
        #expect(changed) // moved from index 1 to index 2
        #expect(store.focusedIndex == 2)
    }

    // MARK: - Empty Ring

    @Test("reconcileFocus handles empty ring gracefully")
    func emptyRing() {
        let store = FocusStore()
        store.register(interaction: .activate, region: region, sectionID: nil, bindingKey: nil, autoKey: "a")
        store.reconcileFocus()
        #expect(store.focusedIndex == 0)

        // All controls disappear
        store.beginFrame()
        let changed = store.reconcileFocus()
        #expect(changed)
        #expect(store.focusedIndex == nil)
    }
}
