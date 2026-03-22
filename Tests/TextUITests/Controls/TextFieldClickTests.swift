import Testing
@testable import TextUI

/// Creates a TextField with a fixed identity for click testing.
@MainActor
private func testField(
    _ placeholder: String = "",
    text: String,
    onChange: @escaping (String) -> Void = { _ in },
) -> TextField {
    TextField(placeholder, text: text, fileID: "clicktest", line: 1, onChange: onChange)
}

@MainActor
@Suite("TextField Click")
struct TextFieldClickTests {
    @Test("Click at column 0 positions cursor at character 0")
    func clickAtStart() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let field = testField(text: "hello")
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        // First render to register focus entry + tap handler
        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        // Fire tap handler at column 0
        let entry = store.entry(at: 0, column: 0)
        #expect(entry != nil)
        let tap = try store.tapHandler(for: #require(entry?.id))
        #expect(tap != nil)
        tap?(0, 0)

        // Verify cursor moved to position 0
        let editState = store.controlState(forKey: AnyHashable("clicktest:1"), as: TextField.EditState.self)
        #expect(editState?.cursor == 0)
    }

    @Test("Click at column N positions cursor at character N")
    func clickAtMiddle() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let field = testField(text: "hello")
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 0, column: 3))
        store.tapHandler(for: entry.id)?(0, 3)

        let editState = store.controlState(forKey: AnyHashable("clicktest:1"), as: TextField.EditState.self)
        #expect(editState?.cursor == 3)
    }

    @Test("Click past end of text positions cursor at text.count")
    func clickPastEnd() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let field = testField(text: "hi")
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 0, column: 15))
        store.tapHandler(for: entry.id)?(0, 15)

        let editState = store.controlState(forKey: AnyHashable("clicktest:1"), as: TextField.EditState.self)
        #expect(editState?.cursor == 2)
    }

    @Test("Click with scroll offset correctly maps to character index")
    func clickWithScrollOffset() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        // 10-char wide field with 15 chars of text, cursor at end (15)
        // scrollOffset = 15 - 10 + 1 = 6, so visible chars are indices 6..14
        let field = testField(text: "abcdefghijklmno")
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        // Click at column 0 of the visible area — should be char index 6
        let entry = try #require(store.entry(at: 0, column: 0))
        store.tapHandler(for: entry.id)?(0, 0)

        let editState = store.controlState(forKey: AnyHashable("clicktest:1"), as: TextField.EditState.self)
        #expect(editState?.cursor == 6)
    }

    @Test("Click with non-zero region col correctly offsets")
    func clickWithRegionOffset() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let field = testField(text: "hello")
        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 5, width: 20, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        // Click at screen column 7 — field starts at col 5, so char index = 7 - 5 = 2
        let entry = try #require(store.entry(at: 0, column: 7))
        store.tapHandler(for: entry.id)?(0, 7)

        let editState = store.controlState(forKey: AnyHashable("clicktest:1"), as: TextField.EditState.self)
        #expect(editState?.cursor == 2)
    }
}
