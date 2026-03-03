import Testing
@testable import TextUI

@MainActor
@Suite("TabView")
struct TabViewTests {
    // MARK: - Sizing

    @Test("TabView is greedy on both axes")
    func sizingGreedy() {
        let view = TabView {
            TabView.Tab("Home") { Text("Hello") }
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 40, height: 20))
        #expect(size.width == 40)
        #expect(size.height == 20)
    }

    // MARK: - Tab Bar Rendering

    @Test("Tab bar renders with bracket delimiters and labels")
    func tabBarRendering() {
        let view = TabView {
            TabView.Tab("One") { Text("A") }
            TabView.Tab("Two") { Text("B") }
        }
        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)
        render(view, into: &buffer, region: region)

        // Tab bar on row 0: "[ One │ Two ]"
        #expect(buffer[0, 0].char == "[")
        #expect(buffer[0, 2].char == "O")
        #expect(buffer[0, 3].char == "n")
        #expect(buffer[0, 4].char == "e")
    }

    @Test("Selected tab has bold styling when unfocused")
    func selectedTabBoldWhenUnfocused() {
        let view = TabView {
            TabView.Tab("Home") { Text("Content") }
            TabView.Tab("Other") { Text("Other") }
        }
        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)
        render(view, into: &buffer, region: region)

        // First tab "Home" should be bold (selected, unfocused)
        // " Home " starts at col 1
        #expect(buffer[0, 2].style.bold)
    }

    @Test("Selected tab has inverse styling when focused")
    func selectedTabInverseWhenFocused() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TabView {
            TabView.Tab("Home") { Text("Content") }
        }
        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 30, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        // "Home" label characters should be inverse
        #expect(buffer[0, 2].style.inverse)
    }

    // MARK: - Content Rendering

    @Test("Content area renders selected tab only")
    func contentRendersSelectedTab() {
        let view = TabView {
            TabView.Tab("First") { Text("AAA") }
            TabView.Tab("Second") { Text("BBB") }
        }
        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)
        render(view, into: &buffer, region: region)

        // First tab content "AAA" renders on row 1
        #expect(buffer[1, 0].char == "A")
        #expect(buffer[1, 1].char == "A")
        #expect(buffer[1, 2].char == "A")
    }

    // MARK: - Tab Switching

    @Test("Left/Right keys switch tabs")
    func tabSwitching() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TabView {
            TabView.Tab("First") { Text("AAA") }
            TabView.Tab("Second") { Text("BBB") }
        }

        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Switch to second tab
        let result = store.routeKeyEvent(.right)
        #expect(result == .handled)

        store.beginFrame()
        buffer = Buffer(width: 30, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        // Content should now be "BBB"
        #expect(buffer[1, 0].char == "B")
    }

    @Test("Left key wraps around to last tab")
    func leftKeyWraps() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TabView {
            TabView.Tab("First") { Text("AAA") }
            TabView.Tab("Second") { Text("BBB") }
        }

        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Press left from first tab — should wrap to second
        _ = store.routeKeyEvent(.left)

        store.beginFrame()
        buffer = Buffer(width: 30, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(buffer[1, 0].char == "B")
    }

    // MARK: - Focus

    @Test("Tab bar registers in focus ring")
    func tabBarInFocusRing() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TabView {
            TabView.Tab("Home") { Text("Content") }
        }
        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count >= 1)
        #expect(store.ring[0].interaction == .activate)
    }

    @Test("Focusable content children are in separate section from tab bar")
    func contentFocusSectionSeparate() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TabView {
            TabView.Tab("Home") {
                Button("Click") {}
            }
        }
        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        // Tab bar + Button = 2 entries, in different sections
        #expect(store.ring.count == 2)
        #expect(store.ring[0].sectionID != store.ring[1].sectionID)
    }

    // MARK: - State Persistence

    @Test("Selected tab persists across frames")
    func statePersistence() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TabView {
            TabView.Tab("First") { Text("AAA") }
            TabView.Tab("Second") { Text("BBB") }
        }

        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Switch to second tab
        _ = store.routeKeyEvent(.right)

        // Render multiple frames
        for _ in 0 ..< 3 {
            store.beginFrame()
            buffer = Buffer(width: 30, height: 5)
            render(view, into: &buffer, region: region, context: ctx)
        }

        // Still on second tab
        #expect(buffer[1, 0].char == "B")
    }

    // MARK: - Edge Cases

    @Test("Single tab renders correctly")
    func singleTab() {
        let view = TabView {
            TabView.Tab("Only") { Text("Solo") }
        }
        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)
        render(view, into: &buffer, region: region)

        // Tab bar: "[ Only ]"
        #expect(buffer[0, 0].char == "[")
        #expect(buffer[0, 2].char == "O")
        // Content: "Solo"
        #expect(buffer[1, 0].char == "S")
    }
}
