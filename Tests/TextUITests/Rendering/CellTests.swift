import Foundation
import Testing
@testable import TextUI

@Suite("Cell")
struct CellTests {
    @Test("Default cell is blank space with plain style")
    func defaultCell() {
        let cell = Cell()
        #expect(cell.char == " ")
        #expect(cell.style == .plain)
        #expect(!cell.isContinuation)
    }

    @Test("Static blank matches default")
    func staticBlank() {
        #expect(Cell.blank == Cell())
    }

    @Test("Static continuation has flag set")
    func staticContinuation() {
        #expect(Cell.continuation.isContinuation)
    }

    @Test("Equality compares all fields")
    func equality() {
        let a = Cell(char: "A", style: .bold)
        let b = Cell(char: "A", style: .bold)
        let c = Cell(char: "B", style: .bold)
        #expect(a == b)
        #expect(a != c)
        #expect(Cell.blank != Cell.continuation)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let cell = Cell(char: "🎉", style: Style(fg: .red, bold: true), isContinuation: false)
        let data = try JSONEncoder().encode(cell)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == cell)
    }

    @Test("Codable round-trip for continuation cell")
    func codableContinuation() throws {
        let cell = Cell.continuation
        let data = try JSONEncoder().encode(cell)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded == cell)
    }

    @Test("Custom initializer with all parameters")
    func customInit() {
        let cell = Cell(char: "X", style: .dim, isContinuation: true)
        #expect(cell.char == "X")
        #expect(cell.style == .dim)
        #expect(cell.isContinuation)
    }
}
