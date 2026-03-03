import Testing
@testable import TextUI

@MainActor
@Suite("ScrollView")
struct ScrollViewTests {
    // MARK: - Sizing

    @Test("Greedy on height, hugs width")
    func sizingGreedyHeight() {
        let view = ScrollView {
            Text("Hello")
            Text("World")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.height == 10) // Takes all offered height
        #expect(size.width == 5) // Hugs to widest child
    }

    @Test("Ideal size sums child heights")
    func sizingIdealHeight() {
        let view = ScrollView {
            Text("A")
            Text("B")
            Text("C")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: nil, height: nil))
        #expect(size.height == 3)
        #expect(size.width == 1)
    }

    @Test("Empty ScrollView returns zero size")
    func sizingEmpty() {
        let view = ScrollView {}
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size == .zero)
    }

    // MARK: - Rendering

    @Test("Only visible children are rendered in viewport")
    func rendersVisibleChildren() {
        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
            Text("Line4")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region)

        // Should show first 3 lines (offset 0)
        #expect(buffer[0, 0].char == "L")
        #expect(buffer[0, 4].char == "0")
        #expect(buffer[1, 4].char == "1")
        #expect(buffer[2, 4].char == "2")
    }

    @Test("Content shorter than viewport renders without scrolling")
    func contentShorterThanViewport() {
        let view = ScrollView(showsIndicator: false) {
            Text("Hi")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(view, into: &buffer, region: region)

        #expect(buffer[0, 0].char == "H")
        #expect(buffer[0, 1].char == "i")
        // Row 1 should be blank
        #expect(buffer[1, 0].char == " ")
    }

    @Test("Variable-height children render correctly")
    func variableHeightChildren() {
        let view = ScrollView(showsIndicator: false) {
            Text("A\nB") // 2 rows
            Text("C") // 1 row
        }
        var buffer = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        render(view, into: &buffer, region: region)

        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "B")
        #expect(buffer[2, 0].char == "C")
    }

    // MARK: - Scroll Offset

    @Test("Scroll offset persists in FocusStore")
    func scrollOffsetPersistence() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
            Text("Line4")
        }

        // Initial render — default focus applied
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Re-render with focus, then scroll down
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.down)
        #expect(result == .handled)

        // Re-render after scroll
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        // Should now show lines 1-3
        #expect(buffer[0, 4].char == "1")
        #expect(buffer[1, 4].char == "2")
        #expect(buffer[2, 4].char == "3")
    }

    // MARK: - Key Handling

    @Test("Down key scrolls viewport down")
    func downKeyScrolls() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
        }

        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Scroll down twice
        #expect(store.routeKeyEvent(.down) == .handled)
        #expect(store.routeKeyEvent(.down) == .handled)

        store.beginFrame()
        buffer = Buffer(width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(buffer[0, 4].char == "2")
        #expect(buffer[1, 4].char == "3")
    }

    @Test("Up key scrolls viewport up")
    func upKeyScrolls() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
        }

        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Scroll down 2, then up 1
        _ = store.routeKeyEvent(.down)
        _ = store.routeKeyEvent(.down)
        _ = store.routeKeyEvent(.up)

        store.beginFrame()
        buffer = Buffer(width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(buffer[0, 4].char == "1")
        #expect(buffer[1, 4].char == "2")
    }

    @Test("PageDown scrolls by viewport height")
    func pageDownScrolls() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
            Text("Line4")
            Text("Line5")
        }

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        _ = store.routeKeyEvent(.pageDown)

        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        // Should have scrolled by 3 (viewport height)
        #expect(buffer[0, 4].char == "3")
        #expect(buffer[1, 4].char == "4")
        #expect(buffer[2, 4].char == "5")
    }

    @Test("Home scrolls to top")
    func homeScrollsToTop() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
        }

        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        _ = store.routeKeyEvent(.down)
        _ = store.routeKeyEvent(.down)
        _ = store.routeKeyEvent(.home)

        store.beginFrame()
        buffer = Buffer(width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(buffer[0, 4].char == "0")
    }

    @Test("End scrolls to bottom")
    func endScrollsToBottom() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
            Text("Line3")
        }

        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        _ = store.routeKeyEvent(.end)

        store.beginFrame()
        buffer = Buffer(width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)

        // Should show last 2 lines
        #expect(buffer[0, 4].char == "2")
        #expect(buffer[1, 4].char == "3")
    }

    @Test("Scroll offset clamps at boundaries")
    func scrollOffsetClamping() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
        }

        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Try scrolling up past top
        _ = store.routeKeyEvent(.up)

        store.beginFrame()
        buffer = Buffer(width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)

        // Should still be at top
        #expect(buffer[0, 4].char == "0")
        #expect(buffer[1, 4].char == "1")
    }

    // MARK: - Scroll Indicator

    @Test("Scroll indicator shown when content overflows")
    func scrollIndicatorPresent() {
        let view = ScrollView(showsIndicator: true) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
        }
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region)

        // Right edge (col 9) should have indicator characters
        let col9chars = (0 ..< 2).map { buffer[$0, 9].char }
        let hasIndicator = col9chars.contains("█") || col9chars.contains("│")
        #expect(hasIndicator)
    }

    @Test("Scroll indicator not shown when content fits")
    func scrollIndicatorAbsent() {
        let view = ScrollView(showsIndicator: true) {
            Text("Hi")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(view, into: &buffer, region: region)

        // No indicator track on col 9
        let col9chars = (0 ..< 5).map { buffer[$0, 9].char }
        #expect(!col9chars.contains("│"))
        #expect(!col9chars.contains("█"))
    }

    @Test("Scroll indicator hidden when showsIndicator is false")
    func scrollIndicatorHidden() {
        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
        }
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region)

        // No indicator on right edge
        let col9chars = (0 ..< 2).map { buffer[$0, 9].char }
        #expect(!col9chars.contains("│"))
        #expect(!col9chars.contains("█"))
    }

    @Test("Sizing and rendering propose same width to children with indicator")
    func sizingMatchesRenderingWithIndicator() {
        // When showsIndicator is true, both sizeThatFits and render should
        // propose (width - 1) to children, avoiding layout mismatches.
        let view = ScrollView(showsIndicator: true) {
            HStack(spacing: 1) {
                ForEach(["Hi", "Go"]) { item in
                    Text(item)
                        .padding(horizontal: 1)
                        .border(.square)
                }
            }
        }

        // Render into a buffer with indicator space
        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)
        render(view, into: &buffer, region: region)

        // Content width is 19 (20 - 1 for indicator). Each bordered item:
        // border(2) + pad(2) + text(2) = 6 wide, with spacing 1 between = 13 total
        // Check that the first item's border and content rendered correctly
        #expect(buffer[0, 0].char == "┌")
        #expect(buffer[1, 2].char == "H")
        #expect(buffer[1, 3].char == "i")

        // Second item starts at col 7
        #expect(buffer[1, 9].char == "G")
        #expect(buffer[1, 10].char == "o")
    }

    @Test("Content width reduced by 1 when indicator is shown")
    func contentWidthReducedForIndicator() {
        let view = ScrollView(showsIndicator: true) {
            Text("1234567890") // 10 chars
            Text("1234567890")
            Text("1234567890")
        }
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region)

        // Col 8 should be the last content character (9 content cols)
        // Col 9 should be the indicator
        #expect(buffer[0, 8].char == "9") // 9th char of "1234567890"
        let col9char = buffer[0, 9].char
        #expect(col9char == "█" || col9char == "│")
    }

    // MARK: - Focus

    @Test("ScrollView registers in focus ring")
    func focusRegistration() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("A")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count >= 1)
        #expect(store.ring[0].interaction == .activate)
    }

    @Test("Focusable children inside ScrollView are in focus ring")
    func focusableChildrenInRing() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Button("A") {}
            Button("B") {}
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        // ScrollView + 2 buttons = 3 entries
        #expect(store.ring.count == 3)
    }

    @Test("Ancestor handler intercepts scroll keys when child is focused")
    func ancestorHandlerScrollsWhenChildFocused() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Button("A") {}
            Button("B") {}
            Button("C") {}
            Button("D") {}
            Button("E") {}
        }

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Focus second entry (first button, since ScrollView is index 0)
        store.focusNext()

        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        // Button "A" is focused. Send .down — should scroll via ancestor handler
        let result = store.routeKeyEvent(.down)
        #expect(result == .handled)
    }

    // MARK: - Empty ScrollView

    @Test("Empty ScrollView renders without crash")
    func emptyScrollViewRenders() {
        let view = ScrollView {}
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(view, into: &buffer, region: region)
        // Should not crash; buffer should be blank
        #expect(buffer[0, 0].char == " ")
    }

    // MARK: - Partially visible children

    @Test("Child clipped at bottom still renders with full layout height")
    func bottomClipPreservesLayout() {
        // When a child extends below the viewport, it must still be
        // rendered at its full height (via temp buffer) so its internal
        // layout algorithm allocates correctly. Previously, the child
        // was rendered with only the visible height, causing VStack
        // greedy allocation to under-allocate to children.
        let view = ScrollView(showsIndicator: false) {
            VStack(spacing: 1) {
                Text("First")
                Text("Second")
                Text("Third")
                Text("Fourth")
                Text("Fifth")
                Text("Sixth")
            }
        }
        // Viewport of 4 rows, content = 6 lines + 5 spacing = 11 rows
        // At scrollOffset 0, child is clipped at bottom (11 > 4).
        var buffer = Buffer(width: 10, height: 4)
        let region = Region(row: 0, col: 0, width: 10, height: 4)
        render(view, into: &buffer, region: region)

        // First child should render correctly even though content overflows
        #expect(buffer[0, 0].char == "F")
        #expect(buffer[0, 1].char == "i")
        #expect(buffer[0, 2].char == "r")
        // Second child at row 2 (row 0 + spacing 1 + row 1)
        #expect(buffer[2, 0].char == "S")
        #expect(buffer[2, 1].char == "e")
    }

    @Test("Bordered items in VStack inside ScrollView render content")
    func borderedItemsInScrollViewVStack() {
        // Reproduces the demo bug: HStack with bordered padded Text
        // inside a VStack inside ScrollView. When viewport < content
        // height, the VStack must still lay out at full height.
        let view = ScrollView(showsIndicator: false) {
            VStack(spacing: 1) {
                Text("Header")
                HStack(spacing: 1) {
                    Text("Hi")
                        .padding(horizontal: 1)
                        .border(.square)
                    Text("Go")
                        .padding(horizontal: 1)
                        .border(.square)
                }
                Text("Footer")
            }
        }
        // Content: Header(1) + sp(1) + HStack(3) + sp(1) + Footer(1) = 7
        // Use viewport of 5 to trigger bottom-clip
        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)
        render(view, into: &buffer, region: region)

        // Header should be at row 0
        #expect(buffer[0, 0].char == "H")

        // HStack border at row 2 (Header + spacing)
        #expect(buffer[2, 0].char == "┌")

        // Text content inside border at row 3
        // Border col 0=┌, inner: col 1=space(pad), col 2=H, col 3=i
        #expect(buffer[3, 2].char == "H")
        #expect(buffer[3, 3].char == "i")
    }

    @Test("Partially visible child at bottom is clipped")
    func partiallyVisibleBottom() {
        let view = ScrollView(showsIndicator: false) {
            Text("AA\nAA") // 2 rows
            Text("BB\nBB") // 2 rows
        }
        var buffer = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        render(view, into: &buffer, region: region)

        // First child fully visible (rows 0-1), second child partially (row 2 only)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "A")
        #expect(buffer[2, 0].char == "B") // First row of second child
    }
}
