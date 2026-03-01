import Testing
@testable import TextUI

/// Thread-safe mutable flag for use in `@Sendable` test closures.
private final class Flag: @unchecked Sendable {
    var value: Bool = false
}

@Suite("FocusStore")
struct FocusStoreTests {
    // MARK: - Ring Construction

    @Test("Register adds entries to ring")
    func registerAddsEntries() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let id1 = store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "key1",
        )
        let id2 = store.register(
            interaction: .edit,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "key2",
        )

        #expect(store.ring.count == 2)
        #expect(id1 == 0)
        #expect(id2 == 1)
        #expect(store.ring[0].interaction == .activate)
        #expect(store.ring[1].interaction == .edit)
    }

    @Test("beginFrame clears ring and inline handlers")
    func beginFrameResetsRing() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "key1",
        )
        store.applyDefaultFocus()
        #expect(store.ring.count == 1)
        #expect(store.focusedIndex == 0)

        store.beginFrame()
        #expect(store.ring.isEmpty)
        #expect(store.focusedIndex == 0) // persists across frames
    }

    // MARK: - Tab Navigation

    @Test("Tab cycles forward through ring with wrap-around")
    func tabCyclesForward() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        for i in 0 ..< 3 {
            store.register(
                interaction: .activate,
                region: region,
                sectionID: nil,
                bindingKey: nil,
                autoKey: "key\(i)",
            )
        }
        store.applyDefaultFocus()
        #expect(store.focusedIndex == 0)

        store.focusNext()
        #expect(store.focusedIndex == 1)

        store.focusNext()
        #expect(store.focusedIndex == 2)

        store.focusNext()
        #expect(store.focusedIndex == 0) // wrap
    }

    @Test("Shift-Tab cycles backward through ring with wrap-around")
    func shiftTabCyclesBackward() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        for i in 0 ..< 3 {
            store.register(
                interaction: .activate,
                region: region,
                sectionID: nil,
                bindingKey: nil,
                autoKey: "key\(i)",
            )
        }
        store.applyDefaultFocus()

        store.focusPrevious()
        #expect(store.focusedIndex == 2) // wrap to last

        store.focusPrevious()
        #expect(store.focusedIndex == 1)
    }

    @Test("Focus navigation on empty ring is safe")
    func emptyRingNavigation() {
        let store = FocusStore()
        store.focusNext()
        #expect(store.focusedIndex == nil)

        store.focusPrevious()
        #expect(store.focusedIndex == nil)
    }

    // MARK: - Programmatic Focus

    @Test("setFocusByBindingKey moves focus to matching entry")
    func programmaticFocusByBindingKey() {
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
        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("submit"),
            autoKey: nil,
        )

        store.setFocusByBindingKey(AnyHashable("email"))
        #expect(store.focusedIndex == 1)
        #expect(store.isFocusedByBindingKey(AnyHashable("email")))

        store.setFocusByBindingKey(AnyHashable("submit"))
        #expect(store.focusedIndex == 2)

        store.setFocusByBindingKey(nil)
        #expect(store.focusedIndex == nil)
    }

    @Test("focusedBindingKey returns the current entry's binding key")
    func focusedBindingKey() {
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
        #expect(store.focusedBindingKey == AnyHashable("name"))
    }

    // MARK: - Key Routing

    @Test("routeKeyEvent calls inline handler first")
    func routeKeyInlineHandler() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let id = store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "btn",
        )
        store.applyDefaultFocus()

        let called = Flag()
        store.registerInlineHandler(for: id) { key in
            if key == .enter {
                called.value = true
                return .handled
            }
            return .ignored
        }

        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(called.value)
    }

    @Test("routeKeyEvent falls through to ancestor onKeyPress chain")
    func routeKeyAncestorChain() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let called = Flag()
        store.pushKeyHandler(FocusStore.KeyHandler(handler: { key in
            if key == .escape {
                called.value = true
                return .handled
            }
            return .ignored
        }))

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "btn",
        )
        store.applyDefaultFocus()

        let result = store.routeKeyEvent(.escape)
        #expect(result == .handled)
        #expect(called.value)
    }

    @Test("routeKeyEvent fires onSubmit for Enter on .edit controls")
    func routeKeySubmitOnEdit() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let called = Flag()
        store.pushSubmitHandler(FocusStore.SubmitHandler(handler: {
            called.value = true
        }))

        store.register(
            interaction: .edit,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "field",
        )
        store.applyDefaultFocus()

        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(called.value)
    }

    @Test("routeKeyEvent does not fire onSubmit for .activate controls")
    func noSubmitOnActivate() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let called = Flag()
        store.pushSubmitHandler(FocusStore.SubmitHandler(handler: {
            called.value = true
        }))

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "btn",
        )
        store.applyDefaultFocus()

        let result = store.routeKeyEvent(.enter)
        #expect(result == .ignored)
        #expect(!called.value)
    }

    @Test("routeKeyEvent returns .ignored with no focused entry")
    func routeKeyNoFocus() {
        let store = FocusStore()
        let result = store.routeKeyEvent(.enter)
        #expect(result == .ignored)
    }

    // MARK: - Control State

    @Test("Control state persists and retrieves by key")
    func controlStateStorage() {
        let store = FocusStore()
        let key = AnyHashable("field1")

        store.setControlState(5, forKey: key)
        #expect(store.controlState(forKey: key, as: Int.self) == 5)

        store.setControlState(10, forKey: key)
        #expect(store.controlState(forKey: key, as: Int.self) == 10)
    }

    @Test("Control state returns nil for missing key")
    func controlStateMissing() {
        let store = FocusStore()
        #expect(store.controlState(forKey: AnyHashable("nope"), as: Int.self) == nil)
    }

    // MARK: - Default Focus

    @Test("Default focus targets specific binding key on first frame")
    func defaultFocusTarget() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        store.defaultFocusTarget = AnyHashable("email")

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("name"),
            autoKey: nil,
        )
        store.register(
            interaction: .edit,
            region: region,
            sectionID: nil,
            bindingKey: AnyHashable("email"),
            autoKey: nil,
        )
        store.applyDefaultFocus()
        #expect(store.focusedIndex == 1)
    }

    @Test("Default focus applies only once")
    func defaultFocusAppliesOnce() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "key1",
        )
        store.applyDefaultFocus()
        #expect(store.focusedIndex == 0)

        store.beginFrame()
        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "key1",
        )
        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "key2",
        )
        store.focusNext() // move to index 1
        store.applyDefaultFocus() // should not reset
        #expect(store.focusedIndex == 1)
    }

    // MARK: - Section Navigation

    @Test("Arrow navigation stays within focus section")
    func sectionArrowNavigation() {
        let store = FocusStore()

        store.register(
            interaction: .activate,
            region: Region(row: 0, col: 0, width: 10, height: 1),
            sectionID: 0,
            bindingKey: nil,
            autoKey: "s0-0",
        )
        store.register(
            interaction: .activate,
            region: Region(row: 1, col: 0, width: 10, height: 1),
            sectionID: 0,
            bindingKey: nil,
            autoKey: "s0-1",
        )
        store.register(
            interaction: .activate,
            region: Region(row: 2, col: 0, width: 10, height: 1),
            sectionID: 1,
            bindingKey: nil,
            autoKey: "s1-0",
        )

        store.applyDefaultFocus()
        #expect(store.focusedIndex == 0)

        let result = store.focusInDirection(.down)
        #expect(result == .handled)
        #expect(store.focusedIndex == 1)

        store.focusInDirection(.down)
        #expect(store.focusedIndex == 0) // wraps within section 0
    }

    @Test("Arrow navigation with no section uses entire ring")
    func noSectionArrowNavigation() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "a",
        )
        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "b",
        )
        store.applyDefaultFocus()

        let result = store.focusInDirection(.down)
        #expect(result == .handled)
        #expect(store.focusedIndex == 1)
    }

    // MARK: - Handler Chain Snapshot

    @Test("Registered entry captures current handler chain snapshot")
    func handlerChainSnapshot() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let outerCalled = Flag()
        store.pushKeyHandler(FocusStore.KeyHandler(handler: { _ in
            outerCalled.value = true
            return .handled
        }))

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "first",
        )

        let innerCalled = Flag()
        store.pushKeyHandler(FocusStore.KeyHandler(handler: { _ in
            innerCalled.value = true
            return .handled
        }))

        store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "second",
        )

        #expect(store.ring[0].keyHandlerChain.count == 1)
        #expect(store.ring[1].keyHandlerChain.count == 2)

        // Route to first entry — only outer handler
        store.applyDefaultFocus()
        _ = store.routeKeyEvent(.escape)
        #expect(outerCalled.value)
        #expect(!innerCalled.value)

        // Route to second entry — innermost first = inner handler
        outerCalled.value = false
        store.focusNext()
        _ = store.routeKeyEvent(.escape)
        #expect(innerCalled.value)

        store.popKeyHandler()
        store.popKeyHandler()
    }

    // MARK: - isFocused

    @Test("isFocused returns true only for the focused entry")
    func isFocusedCheck() {
        let store = FocusStore()
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        let id0 = store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "a",
        )
        let id1 = store.register(
            interaction: .activate,
            region: region,
            sectionID: nil,
            bindingKey: nil,
            autoKey: "b",
        )
        store.applyDefaultFocus()

        #expect(store.isFocused(id0))
        #expect(!store.isFocused(id1))
    }
}
